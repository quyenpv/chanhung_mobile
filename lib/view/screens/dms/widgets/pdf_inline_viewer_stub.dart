import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';

class PdfInlineViewer extends StatefulWidget {
  const PdfInlineViewer({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<PdfInlineViewer> createState() => _PdfInlineViewerState();
}

class _PdfInlineViewerState extends State<PdfInlineViewer> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    String token = '';
    String tokenType = '';
    try {
      final sharedPreferences = Get.find<ApiClient>().sharedPreferences;
      token =
          sharedPreferences.getString(SharedPreferenceHelper.accessTokenKey) ??
              '';
      tokenType =
          sharedPreferences.getString(SharedPreferenceHelper.accessTokenType) ??
              'Bearer';
    } catch (_) {}

    Map<String, String> headers = {};
    if (token.isNotEmpty) {
      headers['Authorization'] = '$tokenType $token';
      headers['X-Auth-Token'] = token;
    }

    return SfPdfViewer.network(
      widget.url,
      headers: headers,
      key: _pdfViewerKey,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        debugPrint(
            "PDF Load Failed: ${details.error} - ${details.description}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalStrings.openFileFailed.tr),
              backgroundColor: ColorResources.redColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }
}
