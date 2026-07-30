import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Gửi vị trí định kỳ khi admin bật theo dõi trên web.
class StaffLocationTrackingService extends GetxService
    with WidgetsBindingObserver {
  ApiClient? _apiClient;
  Timer? _timer;
  Timer? _configTimer;
  bool _enabled = false;
  int _intervalSeconds = 60;
  int _minDistanceM = 25;
  bool _running = false;
  bool _pingInFlight = false;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastSentAt;
  String lastStatus = 'idle';

  Future<StaffLocationTrackingService> init() async {
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startIfNeeded();
    }
  }

  /// Gọi sau login / vào dashboard / splash (đã có token).
  Future<void> startIfNeeded() async {
    try {
      if (!Get.isRegistered<ApiClient>()) {
        _log('no ApiClient');
        return;
      }
      _apiClient = Get.find<ApiClient>();
      final token = _apiClient!.sharedPreferences
              .getString(SharedPreferenceHelper.accessTokenKey) ??
          '';
      if (token.trim().isEmpty || token.trim().toLowerCase() == 'null') {
        _log('no token');
        stop();
        return;
      }

      await refreshConfig();
      _configTimer?.cancel();
      _configTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        refreshConfig();
      });
    } catch (e) {
      _log('startIfNeeded error: $e');
    }
  }

  Future<void> refreshConfig() async {
    if (_apiClient == null) return;
    try {
      final url =
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingConfigUrl}';
      final res = await _apiClient!
          .request(url, Method.getMethod, null, passHeader: true);
      _log('config status=${res.statusCode}');
      if (res.statusCode != 200 || res.responseJson.isEmpty) {
        // Lỗi tạm: giữ trạng thái cũ, không tắt ngay
        lastStatus = 'config_http_${res.statusCode}';
        return;
      }
      final json = jsonDecode(res.responseJson);
      if (json is! Map) {
        lastStatus = 'config_bad_json';
        return;
      }
      final rawData = json['data'];
      final data = rawData is Map ? rawData : json;
      final enabled = _asBool(data['enabled']);
      final interval = int.tryParse('${data['interval_seconds']}') ?? 60;
      final minDistance = int.tryParse('${data['min_distance_m']}') ?? 25;
      _intervalSeconds = interval.clamp(30, 600);
      _minDistanceM = minDistance.clamp(0, 500);
      lastStatus = enabled ? 'enabled' : 'disabled_by_server';
      _log('config enabled=$enabled interval=$_intervalSeconds');
      _setEnabled(enabled);
    } catch (e) {
      lastStatus = 'config_error';
      _log('refreshConfig error: $e');
    }
  }

  bool _asBool(dynamic value) {
    if (value == true || value == 1) return true;
    if (value == false || value == 0 || value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'on';
  }

  void _setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _timer?.cancel();
      _timer = null;
      _running = false;
      return;
    }
    if (_running) {
      _restartTimer();
      // Vẫn ping ngay khi config xác nhận đang bật
      _ensurePermissionAndPing();
      return;
    }
    _running = true;
    _ensurePermissionAndPing();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
      _sendPing();
    });
  }

  Future<void> _ensurePermissionAndPing() async {
    final ok = await _ensurePermission();
    if (ok) {
      await _sendPing(force: true);
    } else {
      lastStatus = 'permission_denied';
      _log('permission denied or location service off');
    }
  }

  Future<bool> _ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      _log('permission error: $e');
      return false;
    }
  }

  Future<Position?> _readPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      _log('getCurrentPosition failed: $e — try lastKnown');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _sendPing({bool force = false}) async {
    if (!_enabled || _apiClient == null || _pingInFlight) return;
    _pingInFlight = true;
    try {
      final ok = await _ensurePermission();
      if (!ok) {
        lastStatus = 'permission_denied';
        return;
      }

      final pos = await _readPosition();
      if (pos == null) {
        lastStatus = 'no_position';
        return;
      }

      if (!force &&
          _lastLat != null &&
          _lastLng != null &&
          _minDistanceM > 0) {
        final dist = Geolocator.distanceBetween(
            _lastLat!, _lastLng!, pos.latitude, pos.longitude);
        final secondsSince = _lastSentAt == null
            ? 9999
            : DateTime.now().difference(_lastSentAt!).inSeconds;
        if (dist < _minDistanceM && secondsSince < 300) {
          lastStatus = 'skipped_too_close';
          return;
        }
      }

      final url =
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingPingUrl}';
      final body = <String, dynamic>{
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'accuracy_m': pos.accuracy.toStringAsFixed(1),
        'speed_kmh': (pos.speed.isFinite ? (pos.speed * 3.6) : 0)
            .toStringAsFixed(1),
        'heading': pos.heading.isFinite ? pos.heading.toStringAsFixed(1) : '0',
        'device_platform': Platform.isIOS ? 'ios' : 'android',
      };

      final res = await _apiClient!
          .request(url, Method.postMethod, body, passHeader: true);
      _log('ping status=${res.statusCode} body=${res.responseJson}');
      if (res.statusCode == 200) {
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;
        _lastSentAt = DateTime.now();
        lastStatus = 'ping_ok';
      } else {
        lastStatus = 'ping_http_${res.statusCode}';
      }
    } catch (e) {
      lastStatus = 'ping_error';
      _log('ping error: $e');
    } finally {
      _pingInFlight = false;
    }
  }

  void stop() {
    _enabled = false;
    _running = false;
    _timer?.cancel();
    _timer = null;
    _configTimer?.cancel();
    _configTimer = null;
    lastStatus = 'stopped';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[StaffLocationTracking] $message');
    }
  }
}
