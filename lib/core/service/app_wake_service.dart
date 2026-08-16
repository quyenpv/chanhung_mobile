import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Đánh thức UI app khi lệnh nghe khẩn cấp tới lúc app đang tắt / nằm nền.
class AppWakeService {
  static const MethodChannel _channel = MethodChannel('chanhung/app_wake');
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> bringToForeground({
    String title = 'ChanHung ERP — nghe khẩn cấp',
    String body = 'Đang tự mở app để truyền âm thanh realtime',
  }) async {
    if (!Platform.isAndroid) {
      await _showFullScreenNotification(title, body);
      return;
    }

    try {
      await _channel.invokeMethod('bringToForeground');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppWakeService] native bringToForeground: $e');
      }
    }

    await _showFullScreenNotification(title, body);
  }

  static Future<void> _showFullScreenNotification(
      String title, String body) async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _notifications.initialize(
        const InitializationSettings(android: androidInit),
      );
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'chanhung_emergency_audio',
              'Nghe âm thanh khẩn cấp',
              description: 'Tự mở app để truyền micro realtime',
              importance: Importance.max,
              playSound: true,
            ),
          );

      await _notifications.show(
        7753,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chanhung_emergency_audio',
            'Nghe âm thanh khẩn cấp',
            channelDescription: 'Tự mở app để truyền micro realtime',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppWakeService] fullscreen notification: $e');
      }
    }
  }
}
