import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Background message handler (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý notification khi app ở background/terminated
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

  static Future<void> initialize() async {
    // 1. Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications channel
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

    // 3. Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Foreground message handler
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 5. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 6. When app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  }

  /// Lấy FCM device token để gửi lên backend
  static Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
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
      // Điều hướng dựa theo loại notification
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
