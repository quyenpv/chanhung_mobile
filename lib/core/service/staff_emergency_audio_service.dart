import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
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

  static const String _signalGatewayUrl = 'http://127.0.0.1:3105/api/webrtc/signal';

  @override
  void onInit() {
    super.onInit();
    _log('StaffEmergencyAudioService initialized');
  }

  /// Khởi tạo luồng WebRTC Audio và kết nối tới Admin
  Future<bool> startAudioStream({required int adminUserId, required String channelId}) async {
    if (isStreaming) {
      await stopAudioStream();
    }

    try {
      _log('Starting WebRTC Audio Stream for Admin: $adminUserId, Channel: $channelId');
      _currentAdminUserId = adminUserId;
      _currentChannelId = channelId;

      // 1. Xin quyền Micro
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _log('Microphone permission denied');
        return false;
      }

      // 2. Lấy luồng Microphone
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // 3. Khởi tạo RTCPeerConnection với STUN server
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
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
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          isStreaming = false;
        }
      };

      // 4. Tạo SDP Offer
      final offer = await _peerConnection!.createOffer({'offerToReceiveAudio': false, 'offerToReceiveVideo': false});
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
        _localStream!.getTracks().forEach((track) {
          track.stop();
        });
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
    }
  }

  /// Gửi tín hiệu Signaling qua Node.js Gateway
  Future<void> _sendSignal({
    required int targetUserId,
    required String event,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      
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
      ).timeout(const Duration(seconds: 10));
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
