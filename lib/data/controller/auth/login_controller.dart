import 'dart:convert';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/data/model/auth/login/login_model.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/repo/auth/login_repo.dart';
import 'package:chanhung/data/services/passkey_service.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class LoginController extends GetxController {
  LoginRepo loginRepo;

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  TextEditingController emailController =
      TextEditingController(text: 'customer@demo.com');
  TextEditingController passwordController =
      TextEditingController(text: '123456');

  // Track whether demo text has been cleared on first focus
  bool _emailFirstFocus = true;
  bool _passwordFirstFocus = true;

  List<String> errors = [];
  String? email;
  String? password;
  bool remember = false;
  bool isLoading = true;
  bool isPasskeyLoading = false;
  String? appLogo = '';

  LoginController({required this.loginRepo}) {
    emailFocusNode.addListener(() {
      if (emailFocusNode.hasFocus && _emailFirstFocus) {
        _emailFirstFocus = false;
        emailController.clear();
        update();
      }
    });
    passwordFocusNode.addListener(() {
      if (passwordFocusNode.hasFocus && _passwordFirstFocus) {
        _passwordFirstFocus = false;
        passwordController.clear();
        update();
      }
    });
  }

  Future<void> checkAndGotoNextStep(LoginModel responseModel) async {
    if (remember) {
      await loginRepo.apiClient.sharedPreferences
          .setBool(SharedPreferenceHelper.rememberMeKey, true);
    } else {
      await loginRepo.apiClient.sharedPreferences
          .setBool(SharedPreferenceHelper.rememberMeKey, false);
    }

    await loginRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userIdKey,
        responseModel.data?.clientId.toString() ?? '-1');
    await loginRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.accessTokenKey, responseModel.data?.token ?? '');
    await loginRepo.apiClient.sharedPreferences
        .setString(SharedPreferenceHelper.accessTokenType, 'Bearer');
    await loginRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userEmailKey, emailController.text.trim());
    await loginRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userPasswordKey, passwordController.text.trim());

    Get.offAndToNamed(RouteHelper.dashboardScreen);

    if (remember) {
      changeRememberMe();
    }
  }

  bool isSubmitLoading = false;
  bool get canUsePasskey => PasskeyService.isSupportedBuild;

  void loginUser() async {
    isSubmitLoading = true;
    update();

    ResponseModel model = await loginRepo.loginUser(
        emailController.text.toString(), passwordController.text.toString());

    if (model.statusCode == 200) {
      LoginModel loginModel =
          LoginModel.fromJson(jsonDecode(model.responseJson));
      if (loginModel.success! && (loginModel.data?.token ?? '').isNotEmpty) {
        checkAndGotoNextStep(loginModel);
      } else {
        CustomSnackBar.error(errorList: [LocalStrings.loginFailedTryAgain.tr]);
      }
    } else {
      CustomSnackBar.error(errorList: [model.message]);
    }
    isSubmitLoading = false;
    update();
  }

  Future<void> loginWithPasskey() async {
    if (isSubmitLoading || isPasskeyLoading) {
      return;
    }

    isPasskeyLoading = true;
    update();

    try {
      final optionsResponse = await loginRepo.getPasskeyOptions();
      if (optionsResponse.statusCode != 200 ||
          optionsResponse.responseJson.isEmpty) {
        _showLoginError(optionsResponse.message);
        return;
      }

      final optionsPayload =
          apiPayload(jsonDecode(optionsResponse.responseJson));
      final data = optionsPayload['data'] is Map
          ? Map<String, dynamic>.from(optionsPayload['data'])
          : optionsPayload;
      final challengeId = data['challenge_id']?.toString() ?? '';
      final options = data['options'];
      if (challengeId.isEmpty || options == null) {
        _showLoginError(LocalStrings.somethingWentWrong);
        return;
      }

      final credentialJson =
          await PasskeyService().getCredential(jsonEncode(options));
      final verifyResponse = await loginRepo.verifyPasskey(
        challengeId: challengeId,
        responseJson: credentialJson,
      );

      if (verifyResponse.statusCode == 200) {
        final loginModel =
            LoginModel.fromJson(jsonDecode(verifyResponse.responseJson));
        if (loginModel.success == true &&
            (loginModel.data?.token ?? '').isNotEmpty) {
          await checkAndGotoNextStep(loginModel);
        } else {
          _showLoginError(LocalStrings.loginFailedTryAgain);
        }
      } else {
        _showLoginError(verifyResponse.message);
      }
    } on PasskeyException catch (error) {
      _showLoginError(error.message);
    } catch (_) {
      _showLoginError(LocalStrings.somethingWentWrong);
    } finally {
      isPasskeyLoading = false;
      update();
    }
  }

  changeRememberMe() {
    remember = !remember;
    update();
  }

  void initData() async {
    isLoading = true;
    update();
    appLogo = loginRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.appLogo);

    isLoading = false;
    update();
  }

  void clearTextField() {
    passwordController.text = '';
    emailController.text = '';
    _emailFirstFocus = true;
    _passwordFirstFocus = true;
    if (remember) {
      remember = false;
    }
    update();
  }

  void _showLoginError(String message) {
    CustomSnackBar.error(errorList: [message.tr]);
  }
}
