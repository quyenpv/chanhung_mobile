import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Thông báo dạng dialog (tương tự SwalHelper trên web ERP).
class AppAlert {
  static Future<void> error(String message, {String? title}) {
    return _show(
      title: title ?? LocalStrings.error.tr,
      message: message,
      icon: Icons.error_outline,
      iconColor: ColorResources.colorRed,
    );
  }

  static Future<void> success(String message, {String? title}) {
    return _show(
      title: title ?? LocalStrings.success.tr,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: ColorResources.colorGreen,
    );
  }

  static Future<void> warning(String message, {String? title}) {
    return _show(
      title: title ?? LocalStrings.warning.tr,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: ColorResources.yellowColor,
    );
  }

  static Future<void> _show({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final text = message.trim().isEmpty
        ? LocalStrings.somethingWentWrong.tr
        : message.trim();

    Future<void> present() async {
      BuildContext? context =
          Get.overlayContext ?? Get.context ?? Get.key.currentContext;

      // Đợi 1 frame nếu context chưa sẵn sàng (sau await API / đóng dialog).
      if (context == null || !context.mounted) {
        await Future<void>.delayed(Duration.zero);
        await SchedulerBinding.instance.endOfFrame;
        context =
            Get.overlayContext ?? Get.context ?? Get.key.currentContext;
      }

      if (context == null || !context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Text(
                    title,
                    style: mediumLarge.copyWith(color: iconColor),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                text,
                style: regularDefault.copyWith(
                  color: ColorResources.contentTextColor,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: ColorResources.colorWhite,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(LocalStrings.close.tr),
              ),
            ],
          );
        },
      );
    }

    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      final done = Future<void>.delayed(Duration.zero);
      binding.addPostFrameCallback((_) {
        present();
      });
      return done;
    }

    return present();
  }
}
