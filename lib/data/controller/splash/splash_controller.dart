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
import 'package:chanhung/data/repo/splash/splash_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:chanhung/core/service/ota_update_service.dart';
import 'package:chanhung/view/components/dialog/update_dialog.dart';
import 'package:http/http.dart' as http;

class SplashController extends GetxController {
  SplashRepo splashRepo;
  LocalizationController localizationController;
  bool isLoading = true;
  bool _isNavigating = false;

  /// Chỉ hiện dialog cập nhật 1 lần mỗi lần khởi động app.
  bool _updateDialogShownThisSession = false;

  static const String publicGitHubReleasesApi =
      'https://api.github.com/repos/quyenpv/chanhung_mobile_releases/releases/latest';
  static const String publicGitHubReleasesUrl =
      'https://github.com/quyenpv/chanhung_mobile_releases/releases/latest';

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
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      String latestVersion = '1.0.0';
      String minVersion = '1.0.0';
      String downloadUrl = '';
      String changelog = '';
      bool remoteForceUpdate = false;
      bool fetchedFromErp = false;

      // 1. Kiểm tra cấu hình từ máy chủ ERP
      try {
        ResponseModel response = await splashRepo.getAppConfig();
        if (response.statusCode == 200) {
          var json = jsonDecode(response.responseJson);
          if (json != null && json['success'] == true && json['data'] != null) {
            var config = json['data'];
            latestVersion = config['latest_app_version'] ??
                config['current_app_version'] ??
                '1.0.0';
            minVersion = config['min_app_version'] ?? '1.0.0';
            downloadUrl = (config['apk_download_url'] ??
                    config['github_release_url'] ??
                    '')
                .toString()
                .trim();
            changelog = (config['update_changelog'] ?? '').toString();
            remoteForceUpdate = config['force_update'] ?? false;
            fetchedFromErp = true;
          }
        }
      } catch (_) {}

      // 2. Kiểm tra trực tiếp từ GitHub Releases công khai (quyenpv/chanhung_mobile_releases)
      try {
        final ghRes = await http.get(Uri.parse(publicGitHubReleasesApi), headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ChanHung-Mobile-App',
        }).timeout(const Duration(seconds: 4));

        if (ghRes.statusCode == 200) {
          final ghJson = jsonDecode(ghRes.body);
          if (ghJson is Map<String, dynamic>) {
            String tag =
                (ghJson['tag_name'] ?? '').toString().replaceAll('v', '').trim();
            if (tag.isNotEmpty && _isNewerVersion(latestVersion, tag)) {
              latestVersion = tag;
              if (ghJson['body'] != null &&
                  ghJson['body'].toString().trim().isNotEmpty) {
                changelog = ghJson['body'].toString().trim();
              }
            }

            // Tìm link tải trực tiếp file APK từ GitHub release assets
            if (ghJson['assets'] is List &&
                (ghJson['assets'] as List).isNotEmpty) {
              String? bestApkUrl;
              for (var asset in (ghJson['assets'] as List)) {
                final name = (asset['name'] ?? '').toString().toLowerCase();
                final assetDownloadUrl =
                    asset['browser_download_url']?.toString();
                if (assetDownloadUrl != null && assetDownloadUrl.isNotEmpty) {
                  if (name.contains('app-erp-release.apk')) {
                    bestApkUrl = assetDownloadUrl;
                    break;
                  } else if (name.endsWith('.apk') && bestApkUrl == null) {
                    bestApkUrl = assetDownloadUrl;
                  }
                }
              }
              if (bestApkUrl != null && bestApkUrl.isNotEmpty) {
                downloadUrl = bestApkUrl;
              }
            }

            if (downloadUrl.isEmpty || downloadUrl.contains('drive.google.com')) {
              downloadUrl =
                  'https://github.com/quyenpv/chanhung_mobile_releases/releases/latest/download/app-erp-release.apk';
            }
          }
        }
      } catch (_) {}

      if (downloadUrl.isEmpty || downloadUrl.contains('drive.google.com')) {
        downloadUrl =
            'https://github.com/quyenpv/chanhung_mobile_releases/releases/latest/download/app-erp-release.apk';
      }

      if (_isNewerVersion(currentVersion, latestVersion)) {
        bool isForceUpdate = remoteForceUpdate ||
            _isNewerVersion(currentVersion, minVersion);

        _updateDialogShownThisSession = true;

        await Get.dialog<bool>(
          UpdateDialog(
            isForceUpdate: isForceUpdate,
            latestVersion: latestVersion,
            changelog: changelog.isNotEmpty
                ? changelog
                : 'Đã có bản cập nhật mới trên GitHub Releases.',
            onUpdatePressed: () async {
              await OtaUpdateService.startDownloadAndInstall(
                downloadUrl: downloadUrl.trim(),
                targetVersion: latestVersion,
                onError: (err) {
                  CustomSnackBar.error(
                      errorList: ['Lỗi tải gói cập nhật: $err']);
                },
              );
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
    } catch (e) {
      if (showNoUpdateToast) {
        CustomSnackBar.error(errorList: ['Error checking for updates'.tr]);
      }
    }
  }

  /// Trả về true nếu candidate Version mới hơn current Version (candidate > current)
  bool _isNewerVersion(String current, String candidate) {
    try {
      String cleanCurrent = current.split('+')[0].replaceAll('v', '').trim();
      String cleanCandidate =
          candidate.split('+')[0].replaceAll('v', '').trim();

      List<int> currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      List<int> candidateParts = cleanCandidate
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();

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
