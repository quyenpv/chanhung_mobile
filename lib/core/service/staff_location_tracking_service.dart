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

/// Theo dõi vị trí nền: gửi GPS khi app tắt màn hình / vào nền (Android cần
/// notification hệ thống bắt buộc; iOS cần quyền Always).
class StaffLocationTrackingService extends GetxService
    with WidgetsBindingObserver {
  static const String _prefsEnabledKey = 'staff_location_bg_wanted';
  static const String _prefsIntervalKey = 'staff_location_bg_interval';
  static const String _prefsMinDistanceKey = 'staff_location_bg_min_distance';

  final FlutterBackgroundService _bg = FlutterBackgroundService();
  String lastStatus = 'idle';

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
      startIfNeeded();
    }
  }

  Future<void> _configureBackgroundService() async {
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
        description: 'Đồng bộ dữ liệu ứng dụng',
        importance: Importance.low,
      ),
    );

    await _bg.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: staffLocationBgOnStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: 'ChanHung',
        initialNotificationContent: 'Đồng bộ dữ liệu ứng dụng',
        foregroundServiceNotificationId: 7741,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: staffLocationBgOnStart,
        onBackground: staffLocationBgOnIosBackground,
      ),
    );
  }

  /// Gọi sau login / dashboard / splash.
  Future<void> startIfNeeded() async {
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
          (int.tryParse('${config['interval_seconds']}') ?? 60).clamp(30, 600);
      final minDistance =
          (int.tryParse('${config['min_distance_m']}') ?? 25).clamp(0, 500);

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
      await _pingOnce(token, minDistance, force: true);
      await _startBackground();
      lastStatus = 'bg_running';
      _log('background tracking started interval=$interval');
    } catch (e) {
      lastStatus = 'start_error';
      _log('startIfNeeded error: $e');
    }
  }

  Future<void> stopBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEnabledKey, false);
      // FlutterBackgroundService không có stopService(); dừng qua invoke → stopSelf().
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
      // Xin Always (Android 10+ / iOS) để chạy nền
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      _log('permission error: $e');
      return false;
    }
  }

  Future<void> _startBackground() async {
    final running = await _bg.isRunning();
    if (!running) {
      await _bg.startService();
    } else {
      _bg.invoke('refresh');
    }
  }

  Future<void> _pingOnce(String token, int minDistance,
      {bool force = false}) async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;

      final url = Uri.parse(
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingPingUrl}');
      final body = {
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'accuracy_m': pos.accuracy.toStringAsFixed(1),
        'speed_kmh': (pos.speed.isFinite ? (pos.speed * 3.6) : 0)
            .toStringAsFixed(1),
        'heading': pos.heading.isFinite ? pos.heading.toStringAsFixed(1) : '0',
        'device_platform': Platform.isIOS ? 'ios' : 'android',
      };
      final res = await http
          .post(url,
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'X-Auth-Token': token,
              },
              body: body)
          .timeout(const Duration(seconds: 20));
      _log('ui ping ${res.statusCode}');
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
      title: 'ChanHung',
      content: 'Đồng bộ dữ liệu ứng dụng',
    );
  }

  Future<void> tick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wanted = prefs.getBool('staff_location_bg_wanted') ?? false;
      final token =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      if (!wanted ||
          token.trim().isEmpty ||
          token.trim().toLowerCase() == 'null') {
        service.stopSelf();
        return;
      }

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
              service.stopSelf();
              return;
            }
            final newInterval = int.tryParse('${data['interval_seconds']}');
            if (newInterval != null) {
              await prefs.setInt(
                  'staff_location_bg_interval', newInterval.clamp(30, 600));
            }
            final minD = int.tryParse('${data['min_distance_m']}');
            if (minD != null) {
              await prefs.setInt(
                  'staff_location_bg_min_distance', minD.clamp(0, 500));
            }
          }
        }
      } catch (_) {}

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;

      final pingUrl = Uri.parse(
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingPingUrl}');
      await http
          .post(pingUrl,
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'X-Auth-Token': token,
              },
              body: {
                'latitude': pos.latitude.toString(),
                'longitude': pos.longitude.toString(),
                'accuracy_m': pos.accuracy.toStringAsFixed(1),
                'speed_kmh': (pos.speed.isFinite ? (pos.speed * 3.6) : 0)
                    .toStringAsFixed(1),
                'heading':
                    pos.heading.isFinite ? pos.heading.toStringAsFixed(1) : '0',
                'device_platform': Platform.isIOS ? 'ios' : 'android',
              })
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  service.on('stop').listen((event) {
    service.stopSelf();
  });
  service.on('refresh').listen((event) {
    tick();
  });

  await tick();
  final prefs = await SharedPreferences.getInstance();
  final interval =
      (prefs.getInt('staff_location_bg_interval') ?? 60).clamp(30, 600);
  Timer.periodic(Duration(seconds: interval), (_) {
    tick();
  });
}
