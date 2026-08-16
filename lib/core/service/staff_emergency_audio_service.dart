import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/service/app_wake_service.dart';
import 'package:chanhung/core/utils/url_container.dart';

/// Dịch vụ WebRTC Live Audio Stream phục vụ giám sát nghe âm thanh khẩn cấp từ Web Admin.
/// Micro được giữ bởi Foreground Service (location|microphone) để vẫn chạy khi khoá màn hình.
class StaffEmergencyAudioService extends GetxService
    with WidgetsBindingObserver {
  static const String pendingCommandKey = 'pending_emergency_audio_cmd_v1';
  static const String audioFgWantedKey = 'staff_audio_fg_wanted';
  static const String uiHeartbeatKey = 'staff_audio_ui_heartbeat_ms';
  static const int uiHeartbeatStaleMs = 8000;

  StaffEmergencyAudioService({this.runInForegroundService = false});

  final bool runInForegroundService;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool isStreaming = false;
  int? _currentAdminUserId;
  String? _currentChannelId;
  String? _currentSessionId;

  String? _realtimeToken;
  String? _realtimeEventsPath;
  http.Client? _sseClient;
  bool _isDisposed = false;
  bool _isConnectingSse = false;
  bool _observingLifecycle = false;
  Timer? _signalPollTimer;
  Timer? _uiHeartbeatTimer;

  String get _signalGatewayUrl =>
      '${UrlContainer.domainUrl}/chat-realtime/api/webrtc/signal';

  Future<StaffEmergencyAudioService> init() async {
    _log('StaffEmergencyAudioService init() fgs=$runInForegroundService');
    if (!runInForegroundService) {
      _ensureLifecycleObserver();
      try {
        final micStatus = await Permission.microphone.status;
        if (!micStatus.isGranted) {
          try {
            await Permission.microphone.request();
          } catch (_) {}
        }
      } catch (_) {}
      await ensureAudioForegroundService();
      _startUiHeartbeat();
    }
    await consumePendingCommand();
    _startRealtimeSseLoop();
    _startPeriodicSignalPolling();
    return this;
  }

  void _startUiHeartbeat() {
    if (runInForegroundService) return;
    _uiHeartbeatTimer?.cancel();
    unawaited(_touchUiHeartbeat());
    _uiHeartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_touchUiHeartbeat());
    });
  }

  Future<void> _touchUiHeartbeat() async {
    if (runInForegroundService) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        uiHeartbeatKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  static Future<bool> isUiIsolateAlive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final ms = prefs.getInt(uiHeartbeatKey) ?? 0;
      if (ms <= 0) return false;
      return DateTime.now().millisecondsSinceEpoch - ms < uiHeartbeatStaleMs;
    } catch (_) {
      return false;
    }
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _keepMicrophoneAliveInBackground();
    } else if (state == AppLifecycleState.resumed) {
      _startUiHeartbeat();
      unawaited(consumePendingCommand());
      unawaited(_reenableLocalTracks());
    }
  }

  Future<void> _keepMicrophoneAliveInBackground() async {
    await _reenableLocalTracks();
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    await ensureAudioForegroundService();
  }

  Future<void> _reenableLocalTracks() async {
    try {
      if (_localStream == null) return;
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _isDisposed = true;
    if (_observingLifecycle) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
      _observingLifecycle = false;
    }
    _uiHeartbeatTimer?.cancel();
    _signalPollTimer?.cancel();
    _sseClient?.close();
    stopAudioStream();
    super.onClose();
  }

  /// Đánh thức Foreground Service và gửi lệnh start/stop (dùng từ UI isolate hoặc FCM).
  static Future<void> dispatchToForegroundService({
    required String action,
    int adminUserId = 0,
    String channelId = '',
    String sessionId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(audioFgWantedKey, action == 'start');
    await prefs.setString(
      pendingCommandKey,
      jsonEncode({
        'action': action,
        'admin_user_id': adminUserId,
        'channel_id': channelId,
        'session_id': sessionId,
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    final bg = FlutterBackgroundService();
    try {
      if (!await bg.isRunning()) {
        await bg.startService();
        await Future.delayed(const Duration(milliseconds: 800));
      }
      bg.invoke(action == 'stop' ? 'emergency_audio_stop' : 'emergency_audio_start', {
        'admin_user_id': adminUserId,
        'channel_id': channelId,
        'session_id': sessionId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StaffEmergencyAudioService] dispatch FGS error: $e');
      }
    }
  }

  Future<void> consumePendingCommand() async {
    try {
      if (runInForegroundService && await isUiIsolateAlive()) {
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(pendingCommandKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final at = int.tryParse('${decoded['at']}') ?? 0;
      if (at > 0 &&
          DateTime.now().millisecondsSinceEpoch - at > 120000) {
        await prefs.remove(pendingCommandKey);
        return;
      }
      await prefs.remove(pendingCommandKey);
      final action = '${decoded['action'] ?? ''}';
      if (action == 'stop') {
        await stopAudioStream();
        return;
      }
      final adminUserId = int.tryParse('${decoded['admin_user_id']}') ?? 0;
      final channelId = '${decoded['channel_id'] ?? ''}';
      final sessionId = '${decoded['session_id'] ?? ''}';
      if (adminUserId > 0) {
        await startAudioStream(
          adminUserId: adminUserId,
          channelId: channelId.isEmpty ? 'emergency_audio_channel' : channelId,
          sessionId: sessionId,
        );
      }
    } catch (e) {
      _log('consumePendingCommand error: $e');
    }
  }

  static Future<void> ensureAudioForegroundService() async {
    try {
      final bg = FlutterBackgroundService();
      if (!await bg.isRunning()) {
        await bg.startService();
      }
    } catch (_) {}
  }

  /// Lắng nghe SSE từ Gateway để nhận lệnh `emergency_audio.start` từ Admin
  Future<void> _startRealtimeSseLoop() async {
    if (_isDisposed || _isConnectingSse) return;
    _isConnectingSse = true;

    while (!_isDisposed) {
      try {
        await _ensureRealtimeCredentials();

        if (_realtimeToken != null &&
            _realtimeToken!.isNotEmpty &&
            _realtimeEventsPath != null &&
            _realtimeEventsPath!.isNotEmpty) {
          final sseUrl = '${UrlContainer.domainUrl}$_realtimeEventsPath';
          _log('Connecting SSE to: $sseUrl');

          _sseClient = http.Client();
          final request = http.Request('GET', Uri.parse(sseUrl))
            ..headers['Accept'] = 'text/event-stream'
            ..headers['Cache-Control'] = 'no-cache';

          final streamedResponse = await _sseClient!.send(request);

          if (streamedResponse.statusCode == 200) {
            _log('SSE Connected successfully');
            String? currentEvent;
            final lineStream = streamedResponse.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter());

            await for (final line in lineStream) {
              if (_isDisposed) break;

              final trimmed = line.trim();
              if (trimmed.isEmpty) {
                currentEvent = null;
                continue;
              }

              if (trimmed.startsWith('event:')) {
                currentEvent = trimmed.substring(6).trim();
              } else if (trimmed.startsWith('data:')) {
                final dataStr = trimmed.substring(5).trim();
                _handleSseEvent(currentEvent, dataStr);
              }
            }
          } else {
            _log('SSE stream returned status: ${streamedResponse.statusCode}');
            await _ensureRealtimeCredentials(forceRefresh: true);
          }
        }
      } catch (e) {
        _log('SSE stream error: $e');
        await _ensureRealtimeCredentials(forceRefresh: true);
      }

      if (_isDisposed) break;
      _log('SSE disconnected, retrying in 5 seconds...');
      await Future.delayed(const Duration(seconds: 5));
    }

    _isConnectingSse = false;
  }

  /// Polling tín hiệu WebRTC định kỳ từ ERP API Relay (Fallback khi SSE ngắt quãng)
  void _startPeriodicSignalPolling() {
    _signalPollTimer?.cancel();
    _signalPollTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) async {
      if (_isDisposed) return;
      try {
        if (runInForegroundService) {
          if (await isUiIsolateAlive()) {
            return;
          }
        } else {
          await _touchUiHeartbeat();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final token = prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
        if (token.isEmpty) return;

        final url = Uri.parse('${UrlContainer.baseUrl}location_tracking/signals');
        final res = await http.get(url, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token,
        }).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final dynamic dataObj = (json is Map && json['data'] is Map)
              ? json['data']
              : (json is Map ? json : null);
          if (dataObj != null && dataObj['signals'] is List) {
            final list = dataObj['signals'] as List;
            for (final item in list) {
              if (item is Map) {
                final ev = item['event']?.toString();
                final sigData = item['data'];
                if (sigData is Map) {
                  final mapData = Map<String, dynamic>.from(sigData);
                  await _handleCommandEvent(ev, mapData);
                }
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _handleCommandEvent(String? ev, Map<String, dynamic> mapData) async {
    if (runInForegroundService && await isUiIsolateAlive()) {
      if (ev == 'emergency_audio.start' ||
          ev == 'webrtc_answer' ||
          ev == 'webrtc_ice_candidate') {
        return;
      }
    }
    if (ev == 'emergency_audio.start') {
      final adminUserId = int.tryParse('${mapData['admin_user_id']}') ?? 0;
      final channelId = '${mapData['channel_id'] ?? 'emergency_audio_channel'}';
      final sessionId = '${mapData['session_id'] ?? ''}';
      if (adminUserId > 0) {
        await startAudioStream(
          adminUserId: adminUserId,
          channelId: channelId,
          sessionId: sessionId,
        );
      }
    } else if (ev == 'emergency_audio.stop') {
      await stopAudioStream();
    } else if (ev == 'webrtc_answer') {
      await handleAnswer(mapData);
    } else if (ev == 'webrtc_ice_candidate') {
      await handleRemoteCandidate(mapData);
    }
  }

  /// Xử lý các sự kiện nhận được từ SSE Gateway
  void _handleSseEvent(String? event, String dataStr) {
    try {
      _log('Received SSE Event: $event -> $dataStr');
      final Map<String, dynamic> data =
          dataStr.isNotEmpty ? jsonDecode(dataStr) : {};
      unawaited(_handleCommandEvent(event, data));
    } catch (e) {
      _log('Error handling SSE event: $e');
    }
  }

  /// Lấy hoặc cập nhật Realtime Token từ SharedPreferences hoặc API config
  Future<void> _ensureRealtimeCredentials({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (!forceRefresh) {
      _realtimeToken = prefs.getString(SharedPreferenceHelper.realtimeTokenKey);
      _realtimeEventsPath =
          prefs.getString(SharedPreferenceHelper.realtimeEventsPathKey);
    }

    if (forceRefresh ||
        _realtimeToken == null ||
        _realtimeToken!.isEmpty ||
        _realtimeEventsPath == null ||
        _realtimeEventsPath!.isEmpty) {
      final token = prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      if (token.isEmpty) return;

      try {
        final url = Uri.parse(
            '${UrlContainer.baseUrl}${UrlContainer.locationTrackingConfigUrl}');
        final res = await http.get(url, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token,
        }).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final dynamic dataObj = (json is Map && json['data'] is Map)
              ? json['data']
              : (json is Map ? json : null);
          if (dataObj != null && dataObj['realtime'] is Map) {
            final rt = Map<String, dynamic>.from(dataObj['realtime'] as Map);
            _realtimeToken = rt['token']?.toString();
            _realtimeEventsPath = rt['events_path']?.toString();

            if (_realtimeToken != null) {
              await prefs.setString(
                  SharedPreferenceHelper.realtimeTokenKey, _realtimeToken!);
            }
            if (_realtimeEventsPath != null) {
              await prefs.setString(
                  SharedPreferenceHelper.realtimeEventsPathKey,
                  _realtimeEventsPath!);
            }
            _log('Fetched realtime token successfully: path=$_realtimeEventsPath');
          }
        }
      } catch (e) {
        _log('Failed to fetch realtime config: $e');
      }
    }
  }

  Future<void> _configureNativeAudio() async {
    try {
      await WebRTC.initialize();
    } catch (_) {}
    try {
      if (Platform.isAndroid) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      }
    } catch (e) {
      _log('Android audio configuration: $e');
    }
    try {
      if (Platform.isIOS) {
        await Helper.setAppleAudioIOMode(
          AppleAudioIOMode.localAndRemote,
          preferSpeakerOutput: false,
        );
      }
    } catch (e) {
      _log('iOS audio IO mode: $e');
    }
  }

  /// Khởi tạo luồng WebRTC Audio và kết nối tới Admin
  Future<bool> startAudioStream({
    required int adminUserId,
    required String channelId,
    String sessionId = '',
  }) async {
    if (isStreaming &&
        _peerConnection != null &&
        _currentAdminUserId == adminUserId &&
        (sessionId.isEmpty || sessionId == _currentSessionId)) {
      await _reenableLocalTracks();
      return true;
    }

    if (isStreaming || _peerConnection != null || _localStream != null) {
      await stopAudioStream();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    try {
      _log('Starting WebRTC Audio Stream for Admin: $adminUserId, Channel: $channelId');
      _currentAdminUserId = adminUserId;
      _currentChannelId = channelId;
      _currentSessionId = sessionId;

      if (runInForegroundService && !await isUiIsolateAlive()) {
        await AppWakeService.bringToForeground();
      }
      await ensureAudioForegroundService();
      await _configureNativeAudio();
      try {
        await WakelockPlus.enable();
      } catch (_) {}

      try {
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          try {
            await Permission.microphone.request();
          } catch (_) {}
        }
        if (!status.isGranted &&
            await Permission.microphone.status != PermissionStatus.granted) {
          await _showOpenAppNotification(
              'Cần quyền micro để truyền âm thanh khẩn cấp');
          return false;
        }
      } catch (_) {}

      try {
        final ignoreBattery = await Permission.ignoreBatteryOptimizations.status;
        if (!ignoreBattery.isGranted) {
          try {
            await Permission.ignoreBatteryOptimizations.request();
          } catch (_) {}
        }
      } catch (_) {}

      try {
        final bgService = FlutterBackgroundService();
        if (await bgService.isRunning()) {
          bgService.invoke('update_notification', {
            'title': 'ChanHung ERP',
            'content': 'Đang truyền âm thanh khẩn cấp (micro vẫn chạy khi khoá màn hình)',
          });
        }
      } catch (_) {}

      final mediaConstraints = <String, dynamic>{
        'audio': {
          'mandatory': {
            'googEchoCancellation': false,
            'googAutoGainControl': true,
            'googHighpassFilter': true,
            'googNoiseSuppression': true,
          },
          'optional': [],
        },
        'video': false,
      };

      try {
        _localStream =
            await navigator.mediaDevices.getUserMedia(mediaConstraints);
      } catch (e) {
        _log('getUserMedia detailed constraints failed: $e, trying simple audio');
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
      }

      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
        _log('Microphone track active: ${track.id}, enabled: ${track.enabled}');
      }

      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun.cloudflare.com:3478'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _sendSignal(
            targetUserId: adminUserId,
            event: 'webrtc_ice_candidate',
            data: {
              'channel_id': channelId,
              'session_id': sessionId,
              'candidate': candidate.toMap(),
            },
          );
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        _log('WebRTC Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          isStreaming = false;
        }
      };

      final offer = await _peerConnection!.createOffer(
          {'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
      await _peerConnection!.setLocalDescription(offer);

      await _sendSignal(
        targetUserId: adminUserId,
        event: 'webrtc_offer',
        data: {
          'channel_id': channelId,
          'session_id': sessionId,
          'sdp': offer.sdp,
          'type': offer.type,
        },
      );

      isStreaming = true;
      _log('WebRTC Audio Stream offer sent successfully');
      return true;
    } catch (e) {
      _log('Error starting WebRTC Audio Stream: $e');
      await _showOpenAppNotification(
          'Không lấy được micro khi app chạy nền. Hãy mở lại app ChanHung ERP.');
      await stopAudioStream();
      return false;
    }
  }

  Future<void> _showOpenAppNotification(String body) async {
    try {
      final notifications = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await notifications.initialize(
        const InitializationSettings(android: androidInit),
      );
      await notifications.show(
        7752,
        'ChanHung ERP — nghe khẩn cấp',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chanhung_emergency_audio',
            'Nghe âm thanh khẩn cấp',
            channelDescription: 'Đánh thức app để truyền micro realtime',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            autoCancel: false,
            category: AndroidNotificationCategory.call,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode({'type': 'emergency_audio', 'action': 'start'}),
      );
    } catch (e) {
      _log('showOpenAppNotification error: $e');
    }
  }

  /// Xử lý SDP Answer nhận từ Web Admin
  Future<void> handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null || !isStreaming) return;
    try {
      final sdp = data['sdp'] as String?;
      final type = data['type'] as String? ?? 'answer';
      if (sdp != null) {
        final description = RTCSessionDescription(sdp, type);
        await _peerConnection!.setRemoteDescription(description);
        _log('WebRTC Remote Answer set successfully');
      }
    } catch (e) {
      _log('Error setting remote answer: $e');
    }
  }

  /// Xử lý Remote ICE Candidate nhận từ Web Admin
  Future<void> handleRemoteCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null || !isStreaming) return;
    try {
      final candidateMap = data['candidate'] as Map<String, dynamic>?;
      if (candidateMap != null) {
        final candidate = RTCIceCandidate(
          candidateMap['candidate'],
          candidateMap['sdpMid'],
          candidateMap['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        _log('Added Remote ICE Candidate');
      }
    } catch (e) {
      _log('Error adding remote candidate: $e');
    }
  }

  /// Dừng phát âm thanh và dọn dẹp kết nối
  Future<void> stopAudioStream() async {
    _log('Stopping WebRTC Audio Stream');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(audioFgWantedKey, false);
    } catch (_) {}
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }
    } catch (e) {
      _log('Error stopping WebRTC: $e');
    } finally {
      isStreaming = false;
      _currentAdminUserId = null;
      _currentChannelId = null;
      _currentSessionId = null;
      try {
        final bgService = FlutterBackgroundService();
        if (await bgService.isRunning()) {
          bgService.invoke('update_notification', {
            'title': 'ChanHung ERP',
            'content': 'Theo dõi vị trí lộ trình realtime',
          });
        }
      } catch (_) {}
    }
  }

  /// Gửi tín hiệu Signaling qua cả ERP API Relay và Node.js Gateway
  Future<void> _sendSignal({
    required int targetUserId,
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _ensureRealtimeCredentials();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final bearerToken =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';

      try {
        final erpSignalUrl =
            Uri.parse('${UrlContainer.baseUrl}location_tracking/signal');
        await http.post(
          erpSignalUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $bearerToken',
            'X-Auth-Token': bearerToken,
          },
          body: jsonEncode({
            'target_user_id': targetUserId,
            'event': event,
            'data': data,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        _log('ERP API signal error: $e');
      }

      final token = _realtimeToken ?? '';
      if (token.isNotEmpty) {
        try {
          final url = Uri.parse(_signalGatewayUrl);
          await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'token': token,
              'target_user_id': targetUserId,
              'event': event,
              'data': data,
            }),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
    } catch (e) {
      _log('Signal error: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[StaffEmergencyAudioService] $message');
    }
  }
}
