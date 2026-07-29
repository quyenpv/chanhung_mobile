import 'package:chanhung/core/utils/local_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/string_format_helper.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/view/components/dialog/app_alert_dialog.dart';

class CustomSnackBar {
  static void error({required List<String> errorList, int duration = 5}) {
    _show(
      message: _joinMessages(errorList),
      isError: true,
      duration: duration,
    );
  }

  static void success({required List<String> successList, int duration = 5}) {
    _show(
      message: _joinMessages(successList),
      isError: false,
      duration: duration,
    );
  }

  static String _joinMessages(List<String> messages) {
    String message = '';
    if (messages.isEmpty) {
      message = LocalStrings.somethingWentWrong.tr;
    } else {
      for (final element in messages) {
        message = message.isEmpty ? element : "$message\n$element";
      }
    }
    return Converter.removeQuotationAndSpecialCharacterFromString(message);
  }

  /// Không dùng Get.rawSnackbar: trên Flutter web GetX xếp hàng show() bất
  /// đồng bộ và ném "No Overlay widget found" ngoài try/catch.
  /// Ưu tiên dialog (giống Swal trên web), fallback ScaffoldMessenger.
  static void _show({
    required String message,
    required bool isError,
    required int duration,
  }) {
    void present() {
      // Web / sau khi đóng dialog: dialog rõ ràng hơn snackbar GetX.
      if (kIsWeb) {
        if (isError) {
          AppAlert.error(message);
        } else {
          AppAlert.success(message);
        }
        return;
      }

      final scaffoldContext =
          Get.context ?? Get.overlayContext ?? Get.key.currentContext;
      if (scaffoldContext != null && scaffoldContext.mounted) {
        final messenger = ScaffoldMessenger.maybeOf(scaffoldContext);
        if (messenger != null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError
                  ? ColorResources.colorRed
                  : ColorResources.colorGreen,
              duration: Duration(seconds: duration),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(Dimensions.space8),
            ),
          );
          return;
        }
      }

      if (isError) {
        AppAlert.error(message);
      } else {
        AppAlert.success(message);
      }
    }

    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => present());
    } else {
      present();
    }
  }
}
