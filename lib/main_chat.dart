import 'dart:async';
import 'dart:io';

import 'package:chanhung/core/config/app_mode.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/service/notification_service.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/core/utils/themes.dart';
import 'package:chanhung/data/controller/common/theme_controller.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/di_service/di_services.dart' as services;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppMode.chatOnly = true;
    try {
      await Firebase.initializeApp();
      await NotificationService.initialize();
    } catch (_) {}
    HttpOverrides.global = _ChatHttpOverrides();
    final languages = await services.init();
    runApp(ChanHungChatApp(languages: languages));
  }, (error, stack) => debugPrint('ChanHung Chat error: $error'));
}

class ChanHungChatApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  const ChanHungChatApp({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(builder: (theme) {
      return GetBuilder<LocalizationController>(builder: (locale) {
        return GetMaterialApp(
          title: 'ChanHung Chat',
          debugShowCheckedModeBanner: false,
          initialRoute: RouteHelper.splashScreen,
          navigatorKey: Get.key,
          getPages: RouteHelper().routes,
          theme: theme.darkTheme ? dark : light,
          locale: locale.locale,
          translations: Messages(languages: languages),
        );
      });
    });
  }
}

class _ChatHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..badCertificateCallback = (_, __, ___) => true;
}
