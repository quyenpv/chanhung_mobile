import 'dart:convert';

import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:chanhung/data/model/global/overview_model.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/data/repo/splash/splash_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chanhung/view/components/dialog/update_dialog.dart';

class SplashController extends GetxController {
  SplashRepo splashRepo;
  LocalizationController localizationController;
  bool isLoading = true;

  SplashController(
      {required this.splashRepo, required this.localizationController});

  gotoNextPage() async {
    await loadLanguage();
    await checkAppUpdate();
    bool isRemember = splashRepo.apiClient.sharedPreferences
            .getBool(SharedPreferenceHelper.rememberMeKey) ??
        false;
    final savedToken = splashRepo.apiClient.sharedPreferences
            .getString(SharedPreferenceHelper.accessTokenKey) ??
        '';
    final normalizedToken = savedToken.trim().toLowerCase();
    if (isRemember && (normalizedToken.isEmpty || normalizedToken == 'null')) {
      await splashRepo.apiClient.sharedPreferences
          .setBool(SharedPreferenceHelper.rememberMeKey, false);
      isRemember = false;
    }
    bool isOnBoard = splashRepo.apiClient.sharedPreferences
            .getBool(SharedPreferenceHelper.onboardKey) ??
        false;
    noInternet = false;
    update();

    getData(isRemember, isOnBoard);
  }

  Future<void> checkAppUpdate() async {
    await manualVersionCheck(showNoUpdateToast: false);
  }

  Future<void> manualVersionCheck({required bool showNoUpdateToast}) async {
    try {
      ResponseModel response = await splashRepo.getAppConfig();
      if (response.statusCode == 200) {
        var json = jsonDecode(response.responseJson);
        if (json != null && json['success'] == true && json['data'] != null) {
          var config = json['data'];
          String latestVersion = config['latest_app_version'] ?? config['current_app_version'] ?? '1.0.0';
          String minVersion = config['min_app_version'] ?? '1.0.0';
          String downloadUrl = config['apk_download_url'] ?? '';
          String changelog = config['update_changelog'] ?? '';
          bool remoteForceUpdate = config['force_update'] ?? false;

          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          String currentVersion = packageInfo.version;

          if (_isVersionGreater(currentVersion, latestVersion)) {
            bool isForceUpdate = remoteForceUpdate || _isVersionGreater(currentVersion, minVersion);

            if (downloadUrl.isNotEmpty) {
              bool? proceed = await Get.dialog<bool>(
                UpdateDialog(
                  isForceUpdate: isForceUpdate,
                  latestVersion: latestVersion,
                  changelog: changelog,
                  onUpdatePressed: () async {
                    final Uri url = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                      if (!isForceUpdate) {
                        Get.back(result: true);
                      }
                    } else {
                      CustomSnackBar.error(errorList: ['Could not launch update URL']);
                    }
                  },
                ),
                barrierDismissible: !isForceUpdate,
              );

              if (isForceUpdate && (proceed == null || !proceed)) {
                SystemNavigator.pop();
                await Future.delayed(const Duration(seconds: 5));
              }
            } else {
              if (showNoUpdateToast) {
                CustomSnackBar.success(successList: ['You are using the latest version'.tr]);
              }
            }
          } else {
            if (showNoUpdateToast) {
              CustomSnackBar.success(successList: ['You are using the latest version'.tr]);
            }
          }
        } else {
          if (showNoUpdateToast) {
            CustomSnackBar.error(errorList: ['Error checking for updates'.tr]);
          }
        }
      } else {
        if (showNoUpdateToast) {
          CustomSnackBar.error(errorList: ['Error checking for updates'.tr]);
        }
      }
    } catch (e) {
      if (showNoUpdateToast) {
        CustomSnackBar.error(errorList: ['Error checking for updates'.tr]);
      }
    }
  }

  bool _isVersionGreater(String current, String latest) {
    try {
      List<int> currentParts = current.split('.').map((e) => int.parse(e.trim())).toList();
      List<int> latestParts = latest.split('.').map((e) => int.parse(e.trim())).toList();

      int length = currentParts.length > latestParts.length ? currentParts.length : latestParts.length;
      for (int i = 0; i < length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) {
          return true;
        } else if (latestPart < currentPart) {
          return false;
        }
      }
    } catch (e) {
      return current != latest;
    }
    return false;
  }

  bool noInternet = false;
  void getData(bool isRemember, bool isOnBoard) async {
    if (!isRemember) {
      isLoading = false;
      update();

      Future.delayed(const Duration(seconds: 1), () {
        Get.offAndToNamed(
          isOnBoard ? RouteHelper.loginScreen : RouteHelper.onboardScreen,
        );
      });
      return;
    }

    ResponseModel response = await splashRepo.getOverviewData();
    if (response.statusCode == 200) {
      OverviewModel model =
          OverviewModel.fromJson(jsonDecode(response.responseJson));
      if (model.success!) {
        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.appTitle, model.data?.appTitle ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.appLogo, model.data?.appLogo ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.appLanguage, model.data?.language ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.currencySymbol,
            model.data?.currencySymbol ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.currencyPosition,
            model.data?.currencyPosition ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.defaultCurrency,
            model.data?.defaultCurrency ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.disableLogin,
            model.data?.disableLogin ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.disableRegistration,
            model.data?.disableRegistration ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.viewTasks, model.data?.viewTasks ?? '');

        await splashRepo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.viewOverview,
            model.data?.viewOverview ?? '');
      } else {
        CustomSnackBar.error(errorList: [model.message!]);
      }
    } else {
      if (response.statusCode == 503) {
        noInternet = true;
        update();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        isRemember = false;
      }
      if (response.statusCode != 401 && response.statusCode != 403) {
        CustomSnackBar.error(errorList: [response.message]);
      }
    }

    isLoading = false;
    update();

    if (isOnBoard == false) {
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAndToNamed(RouteHelper.onboardScreen);
      });
    } else {
      if (isRemember) {
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAndToNamed(RouteHelper.dashboardScreen);
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAndToNamed(RouteHelper.loginScreen);
        });
      }
    }
  }

  Future<bool> initSharedData() {
    if (!splashRepo.apiClient.sharedPreferences
        .containsKey(SharedPreferenceHelper.countryCode)) {
      return splashRepo.apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.countryCode,
          LocalStrings.appLanguages[0].countryCode);
    }
    if (!splashRepo.apiClient.sharedPreferences
        .containsKey(SharedPreferenceHelper.languageCode)) {
      return splashRepo.apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.languageCode,
          LocalStrings.appLanguages[0].languageCode);
    }
    if (!splashRepo.apiClient.sharedPreferences
        .containsKey(SharedPreferenceHelper.languageListKey)) {
      return splashRepo.apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.languageListKey,
          LocalStrings.appLanguages[0].languageCode);
    }
    return Future.value(true);
  }

  Future<void> loadLanguage() async {
    localizationController.loadCurrentLanguage();
    String languageCode = localizationController.locale.languageCode;
    Map<String, Map<String, String>> language = {};
    final String response =
        await rootBundle.loadString('assets/lang/$languageCode.json');
    var resJson = jsonDecode(response);
    saveLanguageList(response);
    var value = resJson as Map<String, dynamic>;
    Map<String, String> json = {};
    value.forEach((key, value) {
      json[key] = value.toString();
    });
    language[
            '${localizationController.locale.languageCode}_${localizationController.locale.countryCode}'] =
        json;
    Get.addTranslations(Messages(languages: language).keys);
  }

  void saveLanguageList(String languageJson) async {
    await splashRepo.apiClient.sharedPreferences
        .setString(SharedPreferenceHelper.languageListKey, languageJson);
    return;
  }
}
