import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Gửi vị trí định kỳ khi admin bật theo dõi trên web.
/// Không hiện banner/toast trong app khi đang chạy (chỉ nội quy lúc cài).
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
    if (state == AppLifecycleState.resumed && _enabled) {
      _sendPing(force: true);
    }
  }

  /// Gọi sau khi đăng nhập / vào dashboard khi đã có token.
  Future<void> startIfNeeded() async {
    if (!Get.isRegistered<ApiClient>()) {
      return;
    }
    _apiClient = Get.find<ApiClient>();
    final token = _apiClient!.sharedPreferences
            .getString(SharedPreferenceHelper.accessTokenKey) ??
        '';
    if (token.trim().isEmpty || token.trim().toLowerCase() == 'null') {
      stop();
      return;
    }

    await refreshConfig();
    _configTimer?.cancel();
    _configTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      refreshConfig();
    });
  }

  Future<void> refreshConfig() async {
    if (_apiClient == null) return;
    try {
      final url =
          '${UrlContainer.baseUrl}${UrlContainer.locationTrackingConfigUrl}';
      final res = await _apiClient!
          .request(url, Method.getMethod, null, passHeader: true);
      if (res.statusCode != 200 || res.responseJson.isEmpty) {
        _setEnabled(false);
        return;
      }
      final json = jsonDecode(res.responseJson);
      final data = json is Map ? (json['data'] ?? json) : null;
      if (data is! Map) {
        _setEnabled(false);
        return;
      }
      final enabled = data['enabled'] == true || data['enabled'] == 1;
      final interval = int.tryParse('${data['interval_seconds']}') ?? 60;
      final minDistance = int.tryParse('${data['min_distance_m']}') ?? 25;
      _intervalSeconds = interval.clamp(30, 600);
      _minDistanceM = minDistance.clamp(0, 500);
      _setEnabled(enabled);
    } catch (_) {
      // Im lặng — không thông báo cho user
    }
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
    }
  }

  Future<bool> _ensurePermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendPing({bool force = false}) async {
    if (!_enabled || _apiClient == null || _pingInFlight) return;
    _pingInFlight = true;
    try {
      final ok = await _ensurePermission();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

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
      if (res.statusCode == 200) {
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;
        _lastSentAt = DateTime.now();
      }
    } catch (_) {
      // Im lặng
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
  }
}
