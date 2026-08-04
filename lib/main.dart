import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:chanhung/core/service/notification_service.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/core/utils/themes.dart';
import 'package:chanhung/data/controller/common/theme_controller.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'core/di_service/di_services.dart' as services;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrintStack(
        label: 'Unhandled Flutter error: ${details.exceptionAsString()}',
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrintStack(
        label: 'Unhandled platform error: $error',
        stackTrace: stack,
      );
      return true;
    };

    // Initialize Firebase (graceful fallback if google-services.json not yet configured)
    try {
      await Firebase.initializeApp();
      await NotificationService.initialize();
    } catch (error, stack) {
      debugPrintStack(
        label: 'Firebase initialization skipped: $error',
        stackTrace: stack,
      );
      // Firebase not configured yet — skip silently
    }

    HttpOverrides.global = MyHttpOverrides();
    try {
      final languages = await services.init();
      runApp(MyApp(languages: languages));
    } catch (error, stack) {
      debugPrintStack(
        label: 'Application bootstrap failed: $error',
        stackTrace: stack,
      );
      // Never leave the process without a Flutter view when local storage or
      // bundled language data is temporarily unavailable/corrupt.
      runApp(const BootstrapFailureApp());
    }
  }, (error, stack) {
    debugPrintStack(
      label: 'Unhandled application error: $error',
      stackTrace: stack,
    );
  });
}

class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Khong the khoi dong ung dung. Vui long dong va mo lai ung dung.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  const MyApp({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(builder: (theme) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetMaterialApp(
          title: LocalStrings.appName,
          debugShowCheckedModeBanner: false,
          defaultTransition: Transition.noTransition,
          transitionDuration: const Duration(milliseconds: 200),
          initialRoute: RouteHelper.splashScreen,
          navigatorKey: Get.key,
          theme: theme.darkTheme ? dark : light,
          getPages: RouteHelper().routes,
          locale: localizeController.locale,
          translations: Messages(languages: languages),
          fallbackLocale: Locale(localizeController.locale.languageCode,
              localizeController.locale.countryCode),
        );
      });
    });
  }
}
