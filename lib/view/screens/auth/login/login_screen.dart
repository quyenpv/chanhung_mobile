import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/helper/biometric_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/images.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/auth/login_controller.dart';
import 'package:chanhung/data/repo/auth/login_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/buttons/rounded_button.dart';
import 'package:chanhung/view/components/buttons/rounded_loading_button.dart';
import 'package:chanhung/view/components/image/app_logo_image.dart';
import 'package:chanhung/view/components/text-form-field/custom_text_field.dart';
import 'package:chanhung/view/components/text/default_text.dart';
import 'package:chanhung/view/components/will_pop_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(LoginRepo(apiClient: Get.find()));
    Get.put(LoginController(loginRepo: Get.find()));

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Get.find<LoginController>().initData();
      Get.find<LoginController>().remember = false;

      final biometricEnabled = await BiometricHelper.isBiometricEnabled();
      if (biometricEnabled) {
        _authenticateWithBiometrics();
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await BiometricHelper.authenticate();
    if (success) {
      final controller = Get.find<LoginController>();
      final email = controller.loginRepo.apiClient.sharedPreferences
          .getString(SharedPreferenceHelper.userEmailKey);
      final password = controller.loginRepo.apiClient.sharedPreferences
          .getString(SharedPreferenceHelper.userPasswordKey);
      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        controller.emailController.text = email;
        controller.passwordController.text = password;
        controller.loginUser();
      } else {
        Get.snackbar('Đăng nhập sinh trắc học',
            'Vui lòng đăng nhập bằng mật khẩu lần đầu để ghi nhớ tài khoản.');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: '',
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: GetBuilder<LoginController>(
            builder: (controller) => SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: ColorResources.appBarColor,
                      image: DecorationImage(
                        alignment: Alignment.topCenter,
                        image: AssetImage(MyImages.login),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 140.0, bottom: 30.0),
                          child: Center(
                            child: AppLogoImage(
                              logo: MyImages.appLogo,
                              height: 128,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.space20,
                                vertical: Dimensions.space30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalStrings.login.tr,
                                  style: mediumOverLarge.copyWith(
                                      fontSize: Dimensions.fontMegaLarge,
                                      color: Colors.white),
                                ),
                                Text(
                                  LocalStrings.loginDesc.tr,
                                  style: regularDefault.copyWith(
                                      fontSize: Dimensions.fontDefault,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              )),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: Dimensions.space20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomTextField(
                                  animatedLabel: true,
                                  needOutlineBorder: true,
                                  controller: controller.emailController,
                                  labelText: LocalStrings.email.tr,
                                  onChanged: (value) {},
                                  focusNode: controller.emailFocusNode,
                                  nextFocus: controller.passwordFocusNode,
                                  textInputType: TextInputType.emailAddress,
                                  inputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'fieldErrorMsg'.tr;
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                const SizedBox(height: Dimensions.space20),
                                CustomTextField(
                                  animatedLabel: true,
                                  needOutlineBorder: true,
                                  labelText: LocalStrings.password.tr,
                                  controller: controller.passwordController,
                                  focusNode: controller.passwordFocusNode,
                                  onChanged: (value) {},
                                  isShowSuffixIcon: true,
                                  isPassword: true,
                                  textInputType: TextInputType.text,
                                  inputAction: TextInputAction.done,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return LocalStrings.fieldErrorMsg.tr;
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                const SizedBox(height: Dimensions.space20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 25,
                                          height: 25,
                                          child: Checkbox(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Dimensions
                                                              .defaultRadius)),
                                              activeColor:
                                                  ColorResources.primaryColor,
                                              checkColor:
                                                  ColorResources.colorWhite,
                                              value: controller.remember,
                                              side: WidgetStateBorderSide
                                                  .resolveWith(
                                                (states) => BorderSide(
                                                    width: 1.0,
                                                    color: controller.remember
                                                        ? ColorResources
                                                            .getTextFieldEnableBorder()
                                                        : ColorResources
                                                            .getTextFieldDisableBorder()),
                                              ),
                                              onChanged: (value) {
                                                controller.changeRememberMe();
                                              }),
                                        ),
                                        const SizedBox(width: 8),
                                        DefaultText(
                                            text: LocalStrings.rememberMe.tr,
                                            textColor: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .color!
                                                .withValues(alpha: 0.5))
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        controller.clearTextField();
                                        Get.toNamed(
                                            RouteHelper.forgotPasswordScreen);
                                      },
                                      child: DefaultText(
                                          text: LocalStrings.forgotPassword.tr,
                                          textColor:
                                              ColorResources.secondaryColor),
                                    )
                                  ],
                                ),
                                const SizedBox(height: Dimensions.space20),
                                controller.isSubmitLoading
                                    ? const RoundedLoadingBtn()
                                    : RoundedButton(
                                        text: LocalStrings.signIn.tr,
                                        press: () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            controller.loginUser();
                                          }
                                        }),
                                const SizedBox(height: Dimensions.space10),
                                FutureBuilder<bool>(
                                  future: BiometricHelper.isBiometricEnabled(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data == true) {
                                      return InkWell(
                                        onTap: _authenticateWithBiometrics,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.fingerprint,
                                                  color: ColorResources
                                                      .primaryColor,
                                                  size: 28),
                                              SizedBox(width: 8),
                                              Text(
                                                  'Đăng nhập bằng vân tay/FaceID',
                                                  style: TextStyle(
                                                      color: ColorResources
                                                          .primaryColor)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (controller.canUsePasskey) ...[
                                  const SizedBox(height: Dimensions.space10),
                                  controller.isPasskeyLoading
                                      ? const RoundedLoadingBtn()
                                      : SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed:
                                                controller.loginWithPasskey,
                                            icon: const Icon(Icons.key_rounded),
                                            label: Text(
                                              LocalStrings.signInWithPasskey.tr,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  ColorResources.primaryColor,
                                              side: const BorderSide(
                                                color:
                                                    ColorResources.primaryColor,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: Dimensions.space15,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  Dimensions.defaultRadius,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                                const SizedBox(height: Dimensions.space20),
                                if (controller
                                        .loginRepo.apiClient.sharedPreferences
                                        .getString(SharedPreferenceHelper
                                            .disableRegistration) !=
                                    '1')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(LocalStrings.doNotHaveAccount.tr,
                                          overflow: TextOverflow.ellipsis,
                                          style: regularLarge.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .color!
                                                  .withValues(alpha: 0.5),
                                              fontWeight: FontWeight.w400)),
                                      TextButton(
                                        onPressed: () {
                                          Get.offAndToNamed(
                                              RouteHelper.registrationScreen);
                                        },
                                        child: Text(
                                            LocalStrings.createAnAccount.tr,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: regularLarge.copyWith(
                                                color: ColorResources
                                                    .secondaryColor)),
                                      )
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
