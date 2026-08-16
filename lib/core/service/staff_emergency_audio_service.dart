import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/url_container.dart';

/// Dịch vụ WebRTC Live Audio Stream phục vụ giám sát nghe âm thanh khẩn cấp từ Web Admin.
class StaffEmergencyAudioService extends GetxService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool isStreaming = false;
  int? _currentAdminUserId;
  String? _currentChannelId;

  String? _realtimeToken;
  String? _realtimeEventsPath;
  http.Client? _sseClient;
  bool _isDisposed = false;
  bool _isConnectingSse = false;
  Timer? _signalPollTimer;

  String get _signalGatewayUrl =>
      '${UrlContainer.domainUrl}/chat-realtime/api/webrtc/signal';

  Future<StaffEmergencyAudioService> init() async {
    _log('StaffEmergencyAudioService init() called');
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }
    } catch (_) {}
    _startRealtimeSseLoop();
    _startPeriodicSignalPolling();
    return this;
  }

  @override
  void onClose() {
    _isDisposed = true;
    _signalPollTimer?.cancel();
    _sseClient?.close();
    stopAudioStream();
    super.onClose();
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
        final prefs = await SharedPreferences.getInstance();
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
                  if (ev == 'emergency_audio.start') {
                    final adminUserId = int.tryParse('${mapData['admin_user_id']}') ?? 0;
                    final channelId = '${mapData['channel_id'] ?? 'emergency_audio_channel'}';
                    if (adminUserId > 0) {
                      await startAudioStream(adminUserId: adminUserId, channelId: channelId);
                    }
                  } else if (ev == 'emergency_audio.stop') {
                    await stopAudioStream();
                  } else if (ev == 'webrtc_answer') {
                    await handleAnswer(mapData);
                  } else if (ev == 'webrtc_ice_candidate') {
                    await handleRemoteCandidate(mapData);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  /// Xử lý các sự kiện nhận được từ SSE Gateway
  void _handleSseEvent(String? event, String dataStr) {
    try {
      _log('Received SSE Event: $event -> $dataStr');
      final Map<String, dynamic> data =
          dataStr.isNotEmpty ? jsonDecode(dataStr) : {};

      switch (event) {
        case 'emergency_audio.start':
          final adminUserId = int.tryParse('${data['admin_user_id']}') ?? 0;
          final channelId = '${data['channel_id'] ?? 'emergency_audio_channel'}';
          if (adminUserId > 0) {
            startAudioStream(adminUserId: adminUserId, channelId: channelId);
          }
          break;

        case 'emergency_audio.stop':
          stopAudioStream();
          break;

        case 'webrtc_answer':
          handleAnswer(data);
          break;

        case 'webrtc_ice_candidate':
          handleRemoteCandidate(data);
          break;

        default:
          break;
      }
    } catch (e) {
      _log('Error handling SSE event: $e');
    }
  }

  /// Lấy hoặc cập nhật Realtime Token từ SharedPreferences hoặc API config
  Future<void> _ensureRealtimeCredentials({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
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
            final rt = dataObj['realtime'] as Map<String, dynamic>;
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

  /// Khởi tạo luồng WebRTC Audio và kết nối tới Admin
  Future<bool> startAudioStream(
      {required int adminUserId, required String channelId}) async {
    if (isStreaming || _peerConnection != null || _localStream != null) {
      await stopAudioStream();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      _log('Starting WebRTC Audio Stream for Admin: $adminUserId, Channel: $channelId');
      _currentAdminUserId = adminUserId;
      _currentChannelId = channelId;

      // 1. Xin quyền Micro và Bỏ qua tối ưu pin
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (!status.isGranted) {
        _log('Microphone permission denied');
        return false;
      }

      try {
        final ignoreBattery = await Permission.ignoreBatteryOptimizations.status;
        if (!ignoreBattery.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (_) {}

      // Cập nhật thông báo Foreground Service khi bắt đầu truyền âm thanh
      try {
        final bgService = FlutterBackgroundService();
        if (await bgService.isRunning()) {
          bgService.invoke('update_notification', {
            'title': 'ChanHung ERP',
            'content': '🔴 Đang truyền trực tiếp âm thanh giám sát an toàn',
          });
        }
      } catch (_) {}

      // 2. Lấy luồng Microphone với đầy đủ bộ tiền xử lý âm thanh Android
      final mediaConstraints = <String, dynamic>{
        'audio': {
          'mandatory': {
            'googEchoCancellation': 'true',
            'googAutoGainControl': 'true',
            'googHighpassFilter': 'true',
            'googNoiseSuppression': 'true',
          },
          'optional': [],
        },
        'video': false,
      };
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = true;
        _log('Microphone track active: ${track.id}, enabled: ${track.enabled}');
      }

      // 3. Khởi tạo RTCPeerConnection với STUN server
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

      // Add local audio tracks to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Lắng nghe ICE Candidates và gửi tới Admin qua Signaling Gateway
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _sendSignal(
            targetUserId: adminUserId,
            event: 'webrtc_ice_candidate',
            data: {
              'channel_id': channelId,
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

      // 4. Tạo SDP Offer
      final offer = await _peerConnection!.createOffer(
          {'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
      await _peerConnection!.setLocalDescription(offer);

      // 5. Gửi Offer SDP tới Web Admin
      await _sendSignal(
        targetUserId: adminUserId,
        event: 'webrtc_offer',
        data: {
          'channel_id': channelId,
          'sdp': offer.sdp,
          'type': offer.type,
        },
      );

      isStreaming = true;
      _log('WebRTC Audio Stream offer sent successfully');
      return true;
    } catch (e) {
      _log('Error starting WebRTC Audio Stream: $e');
      await stopAudioStream();
      return false;
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
      final bearerToken =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';

      // 1. Gửi trực tiếp tới ERP API Relay (100% tin cậy, không phụ thuộc Gateway SSE)
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

      // 2. Gửi qua Gateway nếu có
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
