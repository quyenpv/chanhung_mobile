import 'dart:convert';
import 'package:chanhung/core/service/staff_emergency_audio_service.dart';
import 'package:chanhung/core/service/app_wake_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await _wakeEmergencyAudioIfNeeded(message);
}

Future<void> _wakeEmergencyAudioIfNeeded(RemoteMessage message) async {
  final data = message.data;
  final type = '${data['type'] ?? ''}';
  final action = '${data['action'] ?? ''}';
  if (type != 'emergency_audio' && action != 'start' && action != 'stop') {
    if (type != 'emergency_audio') return;
  }
  final adminUserId = int.tryParse('${data['admin_user_id'] ?? '0'}') ?? 0;
  final channelId = '${data['channel_id'] ?? 'emergency_audio_channel'}';
  final sessionId = '${data['session_id'] ?? ''}';
  final resolvedAction = action == 'stop' ? 'stop' : 'start';
  try {
    await StaffEmergencyAudioService.dispatchToForegroundService(
      action: resolvedAction,
      adminUserId: adminUserId,
      channelId: channelId,
      sessionId: sessionId,
    );
    if (resolvedAction == 'start') {
      await AppWakeService.bringToForeground();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[FCM] wake emergency audio error: $e');
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chanhung_high_importance',
    'Thông báo ChanHung ERP',
    description: 'Thông báo duyệt đơn, nhắc việc và cập nhật hệ thống',
    importance: Importance.high,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _emergencyChannel =
      AndroidNotificationChannel(
    'chanhung_emergency_audio',
    'Nghe âm thanh khẩn cấp',
    description: 'Đánh thức app để truyền micro realtime',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_emergencyChannel);

    FirebaseMessaging.onMessage.listen((message) {
      _wakeEmergencyAudioIfNeeded(message);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _wakeEmergencyAudioIfNeeded(message);
      _handleNotificationNavigation(message);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _wakeEmergencyAudioIfNeeded(initial);
    }
  }

  /// Lấy FCM device token để gửi lên backend
  static Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.data['type'] == 'emergency_audio') {
      await _localNotifications.show(
        7752,
        message.notification?.title ?? 'ChanHung ERP — nghe khẩn cấp',
        message.notification?.body ??
            'Quản trị viên đang yêu cầu truyền âm thanh realtime',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _emergencyChannel.id,
            _emergencyChannel.name,
            channelDescription: _emergencyChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.call,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    _handleNotificationPayload(response.payload);
  }

  static void _handleNotificationNavigation(RemoteMessage message) {
    _handleNotificationPayload(jsonEncode(message.data));
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'emergency_audio') {
        StaffEmergencyAudioService.dispatchToForegroundService(
          action: '${data['action'] ?? 'start'}' == 'stop' ? 'stop' : 'start',
          adminUserId: int.tryParse('${data['admin_user_id'] ?? '0'}') ?? 0,
          channelId: '${data['channel_id'] ?? 'emergency_audio_channel'}',
          sessionId: '${data['session_id'] ?? ''}',
        );
        return;
      }
      switch (type) {
        case 'leave_approval':
          Get.toNamed('/leave_screen');
          break;
        case 'payment_request':
          Get.toNamed('/payment_requests');
          break;
        case 'task':
          Get.toNamed('/my_tasks_screen');
          break;
        default:
          break;
      }
    } catch (_) {}
  }
}
