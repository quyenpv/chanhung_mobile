import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Hàng đợi bền vững dùng được ở cả UI isolate và background isolate.
/// Điểm GPS luôn được ghi xuống máy trước khi thử gửi lên server.
class _LocationOfflineQueue {
  static const String _key = 'staff_location_offline_queue_v1';
  static const int _maxPoints = 5000;

  static Future<List<Map<String, String>>> _read(
      SharedPreferences prefs) async {
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Map<String, String>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, String>>[];
      return decoded
          .whereType<Map>()
          .map((item) => item
              .map((key, value) => MapEntry(key.toString(), value.toString())))
          .toList();
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  static Future<void> _write(
      SharedPreferences prefs, List<Map<String, String>> queue) async {
    await prefs.setString(_key, jsonEncode(queue));
  }

  static Future<void> enqueue(Map<String, String> point) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _read(prefs);
    final pointId = point['client_point_id'];
    if (pointId != null &&
        queue.any((item) => item['client_point_id'] == pointId)) {
      return;
    }
    queue.add(point);
    queue.sort(
        (a, b) => (a['recorded_at'] ?? '').compareTo(b['recorded_at'] ?? ''));
    if (queue.length > _maxPoints) {
      queue.removeRange(0, queue.length - _maxPoints);
    }
    await _write(prefs, queue);
  }

  static Future<int> flush(String token) async {
    if (token.trim().isEmpty || token.trim().toLowerCase() == 'null') return 0;
    final prefs = await SharedPreferences.getInstance();
    final queue = await _read(prefs);
    var sent = 0;

    while (queue.isNotEmpty) {
      try {
        final url = Uri.parse(
            '${UrlContainer.baseUrl}${UrlContainer.locationTrackingPingUrl}');
        final body = Map<String, String>.from(queue.first)
          ..remove('client_point_id');
        final response = await http
            .post(url,
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                  'X-Auth-Token': token,
                },
                body: body)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode < 200 || response.statusCode >= 300) break;
        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {}
        final payload = decoded is Map && decoded['data'] is Map
            ? decoded['data'] as Map
            : (decoded is Map ? decoded : null);
        final accepted = payload?['accepted'] == true ||
            payload?['accepted'] == 1 ||
            '${payload?['accepted']}' == 'true';
        final reason = '${payload?['reason'] ?? ''}';
        if (!accepted && reason != 'too_close' && reason != 'disabled') break;

        queue.removeAt(0);
        sent++;
        await _write(prefs, queue);
        if (reason == 'disabled') {
          queue.clear();
          await _write(prefs, queue);
          break;
        }
      } catch (_) {
        break;
      }
    }
    return sent;
  }
}

Map<String, String> _locationPayload(Position pos) {
  final recordedAt = pos.timestamp.toUtc().toIso8601String();
  return {
    'client_point_id':
        '${recordedAt}_${pos.latitude.toStringAsFixed(6)}_${pos.longitude.toStringAsFixed(6)}',
    'latitude': pos.latitude.toString(),
    'longitude': pos.longitude.toString(),
    'accuracy_m': pos.accuracy.toStringAsFixed(1),
    'speed_kmh':
        (pos.speed.isFinite && pos.speed >= 0 ? (pos.speed * 3.6) : 0).toStringAsFixed(1),
    'heading': pos.heading.isFinite && pos.heading >= 0 ? pos.heading.toStringAsFixed(1) : '0',
    'device_platform': Platform.isIOS ? 'ios' : 'android',
    'recorded_at': recordedAt,
  };
}

/// Kiểm tra chất lượng điểm GPS:
/// 1. Bán kính sai số <= 120m (chấp nhận cả trong nhà / văn phòng 40-100m, loại bỏ trạm BTS quá xa > 120m).
/// 2. Độ trễ thời gian <= 3 phút.
/// 3. Loại bỏ bước nhảy tốc độ phi thực tế (> 130 km/h) do glitch GPS.
bool _isValidQualityPosition(Position pos, Position? lastPos) {
  // Sai số quá lớn (>120m) -> loại bỏ dữ liệu rác
  if (pos.accuracy <= 0 || pos.accuracy > 120.0) {
    return false;
  }

  // Toạ độ quá cũ từ cache (> 3 phút) -> loại
  final ageSeconds = DateTime.now().toUtc().difference(pos.timestamp.toUtc()).inSeconds.abs();
  if (ageSeconds > 180) {
    return false;
  }

  // Kiểm tra bước nhảy dịch chuyển bất khả thi
  if (lastPos != null) {
    final distanceMeters = Geolocator.distanceBetween(
      lastPos.latitude,
      lastPos.longitude,
      pos.latitude,
      pos.longitude,
    );
    final timeDiffSeconds = pos.timestamp.difference(lastPos.timestamp).inSeconds.abs();
    if (timeDiffSeconds > 0 && timeDiffSeconds < 60) {
      final calculatedSpeedKmh = (distanceMeters / timeDiffSeconds) * 3.6;
      if (calculatedSpeedKmh > 130.0) {
        // Tốc độ bất thường (>130km/h trong thành phố) -> GPS glitch
        return false;
      }
    }
  }

  return true;
}

/// Theo dõi vị trí nền: thu thập toạ độ bám đường liên tục và gửi lên server.
class StaffLocationTrackingService extends GetxService
    with WidgetsBindingObserver {
  static const String _prefsEnabledKey = 'staff_location_bg_wanted';
  static const String _prefsIntervalKey = 'staff_location_bg_interval';
  static const String _prefsMinDistanceKey = 'staff_location_bg_min_distance';

  final FlutterBackgroundService _bg = FlutterBackgroundService();
  String lastStatus = 'idle';
  bool _isStarting = false;
  DateTime? _lastResumeCheck;
  Position? _lastUiPosition;

  Future<StaffLocationTrackingService> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _configureBackgroundService();
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResumeCheck == null ||
          now.difference(_lastResumeCheck!).inSeconds > 60) {
        _lastResumeCheck = now;
        startIfNeeded();
      }
    }
  }

  Future<void> _configureBackgroundService() async {
    try {
      const channelId = 'chanhung_location_sync';
      final notifications = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await notifications.initialize(
        const InitializationSettings(android: androidInit),
      );
      final androidPlugin = notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          'ChanHung sync',
          description: 'Đồng bộ dữ liệu lộ trình nhân sự',
          importance: Importance.low,
        ),
      );

      await _bg.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: staffLocationBgOnStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: channelId,
          initialNotificationTitle: 'ChanHung ERP',
          initialNotificationContent: 'Đang theo dõi vị trí nhân sự bám đường',
          foregroundServiceNotificationId: 7741,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: staffLocationBgOnStart,
          onBackground: staffLocationBgOnIosBackground,
        ),
      );
    } catch (e) {
      _log('Configure background service failed: $e');
    }
  }

  /// Gọi sau login / dashboard.
  Future<void> startIfNeeded() async {
    if (_isStarting) {
      _log('startIfNeeded already running, skipping duplicate call');
      return;
    }
    _isStarting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      if (token.trim().isEmpty || token.trim().toLowerCase() == 'null') {
        await stopBackground();
        lastStatus = 'no_token';
        return;
      }

      final config = await _fetchConfig(token);
      if (config == null) {
        lastStatus = 'config_error';
        return;
      }

      final enabled = config['enabled'] == true;
      final interval =
          (int.tryParse('${config['interval_seconds']}') ?? 60).clamp(15, 600);
      final minDistance =
          (int.tryParse('${config['min_distance_m']}') ?? 20).clamp(0, 500);

      await prefs.setBool(_prefsEnabledKey, enabled);
      await prefs.setInt(_prefsIntervalKey, interval);
      await prefs.setInt(_prefsMinDistanceKey, minDistance);

      if (!enabled) {
        await stopBackground();
        lastStatus = 'disabled_by_server';
        return;
      }

      final permitted = await _ensureAlwaysPermission();
      if (!permitted) {
        lastStatus = 'permission_denied';
        _log('background permission denied');
        return;
      }

      // Ping ngay trên UI isolate rồi start nền
      await _pingOnce(token, minDistance);
      await _startBackground();
      lastStatus = 'bg_running';
      _log('background tracking started interval=$interval');
    } catch (e) {
      lastStatus = 'start_error';
      _log('startIfNeeded error: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stopBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEnabledKey, false);
      if (await _bg.isRunning()) {
        _bg.invoke('stop');
      }
    } catch (_) {}
    lastStatus = 'stopped';
  }

  Future<Map<String, dynamic>?> _fetchConfig(String token) async {
    try {
      final url = Uri.parse(
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingConfigUrl}');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Auth-Token': token,
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map) return null;
      final data = json['data'];
      if (data is Map) {
        return {
          'enabled': _asBool(data['enabled']),
          'interval_seconds': data['interval_seconds'],
          'min_distance_m': data['min_distance_m'],
        };
      }
      return {
        'enabled': _asBool(json['enabled']),
        'interval_seconds': json['interval_seconds'],
        'min_distance_m': json['min_distance_m'],
      };
    } catch (e) {
      _log('fetchConfig error: $e');
      return null;
    }
  }

  bool _asBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value == false || value == 0 || value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  Future<bool> _ensureAlwaysPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      _log('permission error: $e');
      return false;
    }
  }

  Future<void> _startBackground() async {
    try {
      final running = await _bg.isRunning();
      if (!running) {
        await _bg.startService();
      } else {
        _bg.invoke('refresh');
      }
    } catch (e) {
      _log('startBackground error: $e');
    }
  }

  Future<void> _pingOnce(String token, int minDistance) async {
    try {
      await _LocationOfflineQueue.flush(token);
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {}

      if (pos == null || !_isValidQualityPosition(pos, _lastUiPosition)) return;

      // Lọc nhiễu đứng yên
      if (_lastUiPosition != null) {
        final dist = Geolocator.distanceBetween(
          _lastUiPosition!.latitude,
          _lastUiPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        final elapsed = pos.timestamp.difference(_lastUiPosition!.timestamp).inSeconds.abs();
        if (dist < 12.0 && elapsed < 180) {
          return;
        }
      }

      _lastUiPosition = pos;
      await _LocationOfflineQueue.enqueue(_locationPayload(pos));
      final sent = await _LocationOfflineQueue.flush(token);
      _log('ui location queue flushed=$sent');
    } catch (e) {
      _log('ui ping error: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[StaffLocationTracking] $message');
    }
  }
}

@pragma('vm:entry-point')
Future<bool> staffLocationBgOnIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void staffLocationBgOnStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'ChanHung ERP',
      content: 'Theo dõi vị trí lộ trình realtime',
    );
  }

  Position? lastRecordedPos;
  DateTime? lastRecordedTime;
  StreamSubscription<Position>? positionStreamSub;
  Timer? watchdogTimer;

  Future<void> processAndEnqueue(Position pos, String token, int minDistance) async {
    if (!_isValidQualityPosition(pos, lastRecordedPos)) return;

    final now = DateTime.now();
    if (lastRecordedPos != null && lastRecordedTime != null) {
      final dist = Geolocator.distanceBetween(
        lastRecordedPos!.latitude,
        lastRecordedPos!.longitude,
        pos.latitude,
        pos.longitude,
      );
      final elapsed = now.difference(lastRecordedTime!).inSeconds;

      // Lọc trôi dạt toạ độ khi đứng yên: nếu di chuyển < 12m và thời gian < 180s -> bỏ qua
      final effectiveMinDist = minDistance > 0 ? minDistance.toDouble() : 15.0;
      if (dist < effectiveMinDist && elapsed < 180) {
        return;
      }
    }

    lastRecordedPos = pos;
    lastRecordedTime = now;

    await _LocationOfflineQueue.enqueue(_locationPayload(pos));
    await _LocationOfflineQueue.flush(token);
  }

  void setupLocationStream(String token, int minDistance) {
    positionStreamSub?.cancel();

    // Cấu hình vị trí chất lượng cao, bám theo từng đoạn đường (khoảng cách 12m)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 12,
    );

    positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      try {
        await processAndEnqueue(pos, token, minDistance);
      } catch (_) {}
    }, onError: (_) {});
  }

  Future<void> syncConfigAndHeartbeat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wanted = prefs.getBool('staff_location_bg_wanted') ?? false;
      final token =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      if (!wanted ||
          token.trim().isEmpty ||
          token.trim().toLowerCase() == 'null') {
        positionStreamSub?.cancel();
        watchdogTimer?.cancel();
        service.stopSelf();
        return;
      }

      // Đọc cấu hình từ máy chủ
      var minDistance = prefs.getInt('staff_location_bg_min_distance') ?? 20;
      try {
        final cfgUrl = Uri.parse(
            '${UrlContainer.baseUrl}${UrlContainer.locationTrackingConfigUrl}');
        final cfgRes = await http.get(cfgUrl, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token,
        }).timeout(const Duration(seconds: 15));
        if (cfgRes.statusCode == 200) {
          final json = jsonDecode(cfgRes.body);
          final data = (json is Map && json['data'] is Map)
              ? json['data'] as Map
              : (json is Map ? json : null);
          if (data != null) {
            final enabled = data['enabled'] == true ||
                data['enabled'] == 1 ||
                '${data['enabled']}' == '1' ||
                '${data['enabled']}' == 'true';
            if (!enabled) {
              await prefs.setBool('staff_location_bg_wanted', false);
              positionStreamSub?.cancel();
              watchdogTimer?.cancel();
              service.stopSelf();
              return;
            }
            final newInterval = int.tryParse('${data['interval_seconds']}');
            if (newInterval != null) {
              await prefs.setInt(
                  'staff_location_bg_interval', newInterval.clamp(15, 600));
            }
            final minD = int.tryParse('${data['min_distance_m']}');
            if (minD != null) {
              minDistance = minD.clamp(0, 500);
              await prefs.setInt('staff_location_bg_min_distance', minDistance);
            }
          }
        }
      } catch (_) {}

      // Heartbeat: lấy toạ độ hiện tại nếu stream chưa kích hoạt hoặc đang đứng yên lâu
      if (lastRecordedTime == null ||
          DateTime.now().difference(lastRecordedTime!).inSeconds >= 180) {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 12),
            ),
          );
        } catch (_) {}
        if (pos != null) {
          await processAndEnqueue(pos, token, minDistance);
        }
      }

      await _LocationOfflineQueue.flush(token);
    } catch (_) {}
  }

  service.on('stop').listen((event) {
    positionStreamSub?.cancel();
    watchdogTimer?.cancel();
    service.stopSelf();
  });

  service.on('refresh').listen((event) {
    syncConfigAndHeartbeat();
  });

  // Khởi tạo ban đầu
  SharedPreferences.getInstance().then((prefs) {
    final token = prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
    final minDistance = prefs.getInt('staff_location_bg_min_distance') ?? 20;
    if (token.isNotEmpty) {
      setupLocationStream(token, minDistance);
    }
  });

  await syncConfigAndHeartbeat();

  // Watchdog kiểm tra định kỳ mỗi 60s
  watchdogTimer = Timer.periodic(const Duration(seconds: 60), (_) {
    syncConfigAndHeartbeat();
  });
}
