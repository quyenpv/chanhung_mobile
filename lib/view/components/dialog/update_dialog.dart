import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/dimensions.dart';
import '../../../core/utils/color_resources.dart';
import '../../../core/utils/images.dart';
import '../../../core/utils/style.dart';
import '../buttons/rounded_button.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String latestVersion;
  final String changelog;
  final VoidCallback onUpdatePressed;

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.changelog,
    required this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // If force update, do not allow popping (back button press)
        return !isForceUpdate;
      },
      child: Dialog(
        backgroundColor: ColorResources.getCardBgColor(),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: Dimensions.space25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.only(
                    top: Dimensions.space45,
                    bottom: Dimensions.space20,
                    left: Dimensions.space20,
                    right: Dimensions.space20),
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(Dimensions.defaultRadius)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: Dimensions.space15),
                    Text(
                      "${"App Update Available".tr} (v$latestVersion)",
                      style: mediumLarge.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.space12),
                    Text(
                      isForceUpdate
                          ? "New Version Message".tr
                          : "Optional Update Message".tr,
                      style: regularDefault.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8) ??
                              ColorResources.colorBlack.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                    if (changelog.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.space15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Changelog".tr,
                          style: mediumDefault.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: Dimensions.space5),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(Dimensions.space10),
                        decoration: BoxDecoration(
                          color: ColorResources.getScreenBgColor().withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ColorResources.lineColor, width: 0.8),
                        ),
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              changelog,
                              style: regularSmall.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                                      ColorResources.colorBlack.withOpacity(0.7)),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Dimensions.space25),
                    Row(
                      children: [
                        if (!isForceUpdate) ...[
                          Expanded(
                            child: RoundedButton(
                              text: "Later".tr,
                              press: () {
                                Navigator.pop(context, false);
                              },
                              horizontalPadding: 3,
                              verticalPadding: 3,
                              color: ColorResources.colorGrey.withOpacity(0.2),
                              textColor: Theme.of(context).textTheme.bodyMedium?.color ??
                                  ColorResources.colorBlack,
                            ),
                          ),
                          const SizedBox(width: Dimensions.space10),
                        ],
                        Expanded(
                          child: RoundedButton(
                            text: "Update Now".tr,
                            press: onUpdatePressed,
                            horizontalPadding: 3,
                            verticalPadding: 3,
                            color: ColorResources.getPrimaryColor(),
                            textColor: ColorResources.colorWhite,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Positioned(
                top: -35,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        MyImages.appLogo,
                        height: 70,
                        width: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
