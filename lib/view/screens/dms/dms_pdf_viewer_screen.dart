import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/dms/widgets/pdf_inline_viewer.dart';

class DmsPdfViewerScreen extends StatelessWidget {
  const DmsPdfViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final url = args is Map ? (args['url']?.toString().trim() ?? '') : '';
    final title = args is Map
        ? (args['title']?.toString().trim() ?? LocalStrings.viewFile.tr)
        : LocalStrings.viewFile.tr;

    return Scaffold(
      backgroundColor: ColorResources.screenBgColor,
      appBar: CustomAppBar(title: title),
      body: url.isEmpty
          ? NoDataWidget(text: LocalStrings.openFileFailed.tr)
          : PdfInlineViewer(url: url, title: title),
    );
  }
}
