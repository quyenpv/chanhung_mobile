import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/dialog/exit_dialog.dart';
import 'package:chanhung/core/utils/app_design.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool isShowBackBtn;
  final Color bgColor;
  final bool isTitleCenter;
  final bool fromAuth;
  final bool isProfileCompleted;
  final bool isShowActionBtn;
  final Widget? actionWidget;
  final bool isShowActionBtnTwo;
  final Widget? actionWidgetTwo;

  const CustomAppBar({
    super.key,
    this.isProfileCompleted = false,
    this.fromAuth = false,
    this.isTitleCenter = false,
    this.bgColor = AppDesign.canvas,
    this.isShowBackBtn = true,
    required this.title,
    this.isShowActionBtn = false,
    this.actionWidget,
    this.isShowActionBtnTwo = false,
    this.actionWidgetTwo,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 64);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool hasNotification = false;
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isShowBackBtn
        ? AppBar(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            titleSpacing: 4,
            leading: widget.isShowBackBtn
                ? IconButton(
                    onPressed: () {
                      if (widget.fromAuth) {
                        Get.offAllNamed(RouteHelper.loginScreen);
                      } else if (widget.isProfileCompleted) {
                        showExitDialog(Get.context!);
                      } else if (Navigator.of(context).canPop()) {
                        Get.back();
                      } else {
                        String previousRoute = Get.previousRoute;
                        if (previousRoute == '/splash-screen') {
                          Get.offAndToNamed(RouteHelper.dashboardScreen);
                        } else if (previousRoute.isEmpty ||
                            previousRoute == Get.currentRoute) {
                          Get.offAllNamed(RouteHelper.dashboardScreen);
                        } else {
                          Get.offAllNamed(RouteHelper.dashboardScreen);
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppDesign.ink,
                      size: 19,
                    ))
                : const SizedBox.shrink(),
            backgroundColor: widget.bgColor,
            title: Text(
              widget.title.tr,
              style: mediumLarge.copyWith(
                color: AppDesign.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: widget.isTitleCenter,
            actions: [
              Builder(
                builder: (context) {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold?.hasDrawer != true) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppDesign.ink,
                    ),
                    onPressed: scaffold!.openDrawer,
                  );
                },
              ),
              widget.isShowActionBtn
                  ? widget.actionWidget!
                  : const SizedBox.shrink(),
              widget.isShowActionBtnTwo
                  ? widget.actionWidgetTwo!
                  : const SizedBox.shrink(),
              const SizedBox(
                width: 5,
              )
            ],
          )
        : AppBar(
            titleSpacing: 0,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64,
            backgroundColor: widget.bgColor,
            centerTitle: widget.isTitleCenter,
            title: Text(widget.title.tr,
                style: regularLarge.copyWith(
                  color: AppDesign.ink,
                  fontWeight: FontWeight.w700,
                )),
            actions: [
              Builder(
                builder: (context) {
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold?.hasDrawer != true) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).openAppDrawerTooltip,
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: AppDesign.ink,
                    ),
                    onPressed: scaffold!.openDrawer,
                  );
                },
              ),
              widget.isShowActionBtn
                  ? InkWell(
                      onTap: () {
                        Get.toNamed(RouteHelper.profileScreen)?.then((value) {
                          setState(() {
                            hasNotification = false;
                          });
                        });
                      },
                      child: const SizedBox.shrink())
                  : const SizedBox()
            ],
            automaticallyImplyLeading: false,
          );
  }
}
