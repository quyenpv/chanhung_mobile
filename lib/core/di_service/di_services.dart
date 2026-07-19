import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:chanhung/data/repo/splash/splash_repo.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chanhung/data/controller/common/theme_controller.dart';
import 'package:chanhung/data/controller/splash/splash_controller.dart';
import 'package:chanhung/data/services/api_service.dart';

Future<Map<String, Map<String, String>>> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  await _migrateDefaultLanguage(sharedPreferences);

  Get.lazyPut(() => sharedPreferences, fenix: true);
  Get.lazyPut(() => ApiClient(sharedPreferences: Get.find()));
  Get.lazyPut(() => SplashRepo(apiClient: Get.find()));
  Get.lazyPut(() => LocalizationController(sharedPreferences: Get.find()));
  Get.lazyPut(() => SplashController(
      splashRepo: Get.find(), localizationController: Get.find()));
  Get.lazyPut(() => ThemeController(sharedPreferences: Get.find()));

  final languageCode =
      sharedPreferences.getString(SharedPreferenceHelper.languageCode) ?? 'vi';
  final countryCode =
      sharedPreferences.getString(SharedPreferenceHelper.countryCode) ?? 'VN';
  final String response =
      await rootBundle.loadString('assets/lang/$languageCode.json');
  final Map<String, dynamic> resJson = jsonDecode(response);
  final Map<String, String> selectedLanguage = {};
  resJson.forEach((key, value) {
    selectedLanguage[key] = value.toString();
  });

  Map<String, Map<String, String>> language = {};
  language['${languageCode}_$countryCode'] = selectedLanguage;

  return language;
}

Future<void> _migrateDefaultLanguage(
    SharedPreferences sharedPreferences) async {
  final migrated = sharedPreferences
          .getBool(SharedPreferenceHelper.defaultLanguageMigratedKey) ??
      false;
  if (migrated) {
    return;
  }

  await sharedPreferences.setString(SharedPreferenceHelper.languageCode, 'vi');
  await sharedPreferences.setString(SharedPreferenceHelper.countryCode, 'VN');
  await sharedPreferences.setString(
      SharedPreferenceHelper.languageListKey, 'vi');
  await sharedPreferences.setBool(
      SharedPreferenceHelper.defaultLanguageMigratedKey, true);
}
