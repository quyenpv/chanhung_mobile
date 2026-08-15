import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/service/ota_update_service.dart';
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
        if (OtaUpdateService.isDownloading.value) return false;
        return !isForceUpdate;
      },
      child: Dialog(
        backgroundColor: ColorResources.getCardBgColor(),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: Dimensions.space25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: Obx(() {
                  final isDownloading = OtaUpdateService.isDownloading.value;
                  final isCompleted = OtaUpdateService.isCompleted.value;
                  final progress = OtaUpdateService.progress.value;
                  final statusText = OtaUpdateService.statusText.value;
                  final sizeText = OtaUpdateService.sizeText.value;

                  if (isDownloading || isCompleted) {
                    return _buildDownloadProgressView(
                      context,
                      progress: progress,
                      statusText: statusText,
                      sizeText: sizeText,
                      isCompleted: isCompleted,
                    );
                  }

                  return _buildDefaultPromptView(context);
                }),
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
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
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

  Widget _buildDefaultPromptView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Dimensions.space15),
        Text(
          "Đã có phiên bản mới (v$latestVersion)",
          style: mediumLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.space12),
        Text(
          isForceUpdate
              ? "Vui lòng cập nhật để tiếp tục sử dụng các tính năng mới nhất."
              : "Ứng dụng đã có bản cập nhật mới. Bạn có muốn cập nhật ngay?",
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
              "Nội dung cập nhật:",
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
                  text: "Để sau",
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
                text: "Cập nhật ngay",
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
    );
  }

  Widget _buildDownloadProgressView(
    BuildContext context, {
    required double progress,
    required String statusText,
    required String sizeText,
    required bool isCompleted,
  }) {
    final pct = (progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: Dimensions.space20),
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
          size: 48,
          color: isCompleted ? Colors.green : ColorResources.getPrimaryColor(),
        ),
        const SizedBox(height: Dimensions.space12),
        Text(
          isCompleted ? "Tải thành công!" : "Đang tải bản cập nhật (v$latestVersion)",
          style: mediumLarge.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.space15),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 10,
            backgroundColor: ColorResources.lineColor.withOpacity(0.4),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : ColorResources.getPrimaryColor(),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.space10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sizeText.isNotEmpty ? sizeText : "$pct%",
              style: regularSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorResources.getPrimaryColor(),
              ),
            ),
            Text(
              "$pct%",
              style: regularSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorResources.getPrimaryColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.space10),
        Text(
          statusText.isNotEmpty ? statusText : "Đang xử lý...",
          style: regularSmall.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                ColorResources.colorBlack.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.space20),
        if (!isCompleted && !isForceUpdate)
          TextButton(
            onPressed: () {
              OtaUpdateService.cancel();
              Navigator.pop(context, false);
            },
            child: const Text("Huỷ bỏ", style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}
