import 'dart:convert';

import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/config/app_mode.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:chanhung/data/model/global/overview_model.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/service/staff_location_tracking_service.dart';
import 'package:chanhung/core/utils/messages.dart';
import 'package:chanhung/data/controller/localization/localization_controller.dart';
import 'package:chanhung/data/model/global/overview_model.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/service/staff_location_tracking_service.dart';
import 'package:chanhung/data/repo/splash/splash_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chanhung/view/components/dialog/update_dialog.dart';

class SplashController extends GetxController {
  SplashRepo splashRepo;
  LocalizationController localizationController;
  bool isLoading = true;
  bool _isNavigating = false;

  /// Chỉ hiện dialog cập nhật 1 lần mỗi lần khởi động app.
  bool _updateDialogShownThisSession = false;

  SplashController(
      {required this.splashRepo, required this.localizationController});

  Future<void> gotoNextPage() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      await loadLanguage();
      await checkAppUpdate();
      bool isRemember = splashRepo.apiClient.sharedPreferences
              .getBool(SharedPreferenceHelper.rememberMeKey) ??
          false;
      final savedToken = splashRepo.apiClient.sharedPreferences
              .getString(SharedPreferenceHelper.accessTokenKey) ??
          '';
      final normalizedToken = savedToken.trim().toLowerCase();
      if (isRemember &&
          (normalizedToken.isEmpty || normalizedToken == 'null')) {
        await splashRepo.apiClient.sharedPreferences
            .setBool(SharedPreferenceHelper.rememberMeKey, false);
        isRemember = false;
      }
      bool isOnBoard = splashRepo.apiClient.sharedPreferences
              .getBool(SharedPreferenceHelper.onboardKey) ??
          false;
      noInternet = false;
      update();

      await getData(isRemember, isOnBoard);
    } catch (_) {
      isLoading = false;
      noInternet = true;
      update();
      await splashRepo.apiClient.sharedPreferences
          .setBool(SharedPreferenceHelper.rememberMeKey, false);
      Get.offAllNamed(RouteHelper.loginScreen);
    }
  }

  Future<void> checkAppUpdate() async {
    await manualVersionCheck(showNoUpdateToast: false);
  }

  Future<void> manualVersionCheck({required bool showNoUpdateToast}) async {
    // Nếu không phải manual check (showNoUpdateToast=false = auto check),
    // chỉ hiện dialog 1 lần mỗi session để tránh spam lặp.
    if (!showNoUpdateToast && _updateDialogShownThisSession) {
      return;
    }

    try {
      ResponseModel response = await splashRepo.getAppConfig();
      if (response.statusCode == 200) {
        var json = jsonDecode(response.responseJson);
        if (json != null && json['success'] == true && json['data'] != null) {
          var config = json['data'];
          String latestVersion = config['latest_app_version'] ??
              config['current_app_version'] ??
              '1.0.0';
          String minVersion = config['min_app_version'] ?? '1.0.0';
          String downloadUrl = config['apk_download_url'] ??
              config['github_release_url'] ??
              'https://github.com/quyenpv/ChanHung_ERP/releases/latest';
          if (downloadUrl.trim().isEmpty) {
            downloadUrl = 'https://github.com/quyenpv/ChanHung_ERP/releases/latest';
          }
          String changelog = config['update_changelog'] ?? '';
          bool remoteForceUpdate = config['force_update'] ?? false;

          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          String currentVersion = packageInfo.version;

          if (_isNewerVersion(currentVersion, latestVersion)) {
            bool isForceUpdate = remoteForceUpdate ||
                _isNewerVersion(currentVersion, minVersion);

            if (downloadUrl.isNotEmpty) {
              // Đánh dấu đã hiện dialog trong session này (trước khi await).
              _updateDialogShownThisSession = true;

              await Get.dialog<bool>(
                UpdateDialog(
                  isForceUpdate: isForceUpdate,
                  latestVersion: latestVersion,
                  changelog: changelog,
                  onUpdatePressed: () async {
                    final Uri url = Uri.parse(downloadUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                      if (!isForceUpdate) {
                        Get.back(result: true);
                      }
                    } else {
                      CustomSnackBar.error(
                          errorList: ['Could not launch update URL']);
                    }
                  },
                ),
                barrierDismissible: !isForceUpdate,
              );
            } else {
              if (showNoUpdateToast) {
                CustomSnackBar.success(
                    successList: ['You are using the latest version'.tr]);
              }
            }
          } else {
            if (showNoUpdateToast) {
              CustomSnackBar.success(
                  successList: ['You are using the latest version'.tr]);
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

  /// Trả về true nếu candidate Version mới hơn current Version (candidate > current)
  bool _isNewerVersion(String current, String candidate) {
    try {
      List<int> currentParts =
          current.split('.').map((e) => int.parse(e.trim())).toList();
      List<int> candidateParts =
          candidate.split('.').map((e) => int.parse(e.trim())).toList();

      int length = currentParts.length > candidateParts.length
          ? currentParts.length
          : candidateParts.length;
      for (int i = 0; i < length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int candidatePart = i < candidateParts.length ? candidateParts[i] : 0;

        if (candidatePart > currentPart) {
          return true;
        } else if (candidatePart < currentPart) {
          return false;
        }
      }
    } catch (e) {
      return current != candidate;
    }
    return false;
  }

  bool noInternet = false;
  Future<void> getData(bool isRemember, bool isOnBoard) async {
    if (!isRemember) {
      isLoading = false;
      update();

      Future.delayed(const Duration(milliseconds: 300), () {
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
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.offAndToNamed(RouteHelper.onboardScreen);
      });
    } else {
      if (isRemember) {
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.offAndToNamed(AppMode.chatOnly
              ? RouteHelper.teamChatScreen
              : RouteHelper.dashboardScreen);
        });
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
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
