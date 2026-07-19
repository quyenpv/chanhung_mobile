import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/images.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/auth/registration_controller.dart';
import 'package:chanhung/data/repo/auth/signup_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/image/app_logo_image.dart';
import 'package:chanhung/view/components/will_pop_widget.dart';
import 'package:chanhung/view/screens/auth/registration/widget/account_form.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(RegistrationRepo(apiClient: Get.find()));
    Get.put(RegistrationController(registrationRepo: Get.find()));

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<RegistrationController>().initData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RegistrationController>(
      builder: (controller) => WillPopWidget(
        nextRoute: RouteHelper.loginScreen,
        child: SafeArea(
          child: Scaffold(
            body: controller.isLoading
                ? const CustomLoader()
                : SingleChildScrollView(
                    child: Stack(
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
                                padding: const EdgeInsets.only(
                                    top: 140.0, bottom: 30.0),
                                child: Center(
                                  child: AppLogoImage(
                                    logo: controller.appLogo,
                                    height: 60,
                                    color: Colors.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalStrings.signUp.tr,
                                        style: mediumOverLarge.copyWith(
                                            fontSize: Dimensions.fontMegaLarge,
                                            color: Colors.white),
                                      ),
                                      Text(
                                        LocalStrings.signUpNow.tr,
                                        style: regularDefault.copyWith(
                                            fontSize: Dimensions.fontDefault,
                                            color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15.0,
                                      vertical: Dimensions.space20),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const AccountForm(),
                                      const SizedBox(
                                          height: Dimensions.space10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(LocalStrings.alreadyAccount.tr,
                                              style: regularLarge.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .color!
                                                      .withValues(alpha: 0.5),
                                                  fontWeight: FontWeight.w500)),
                                          TextButton(
                                            onPressed: () {
                                              controller.clearAllData();
                                              Get.offAndToNamed(
                                                  RouteHelper.loginScreen);
                                            },
                                            child: Text(LocalStrings.signIn.tr,
                                                style: regularLarge.copyWith(
                                                    color: Theme.of(context)
                                                        .secondaryHeaderColor)),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: AppBar(
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
                              onPressed: () {
                                controller.clearAllData();
                                Get.offAndToNamed(RouteHelper.loginScreen);
                              },
                            ),
                            backgroundColor: Colors.transparent,
                            elevation: 0.0,
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
