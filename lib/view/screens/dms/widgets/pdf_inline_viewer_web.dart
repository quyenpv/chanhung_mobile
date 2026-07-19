import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:web/web.dart' as web;

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
  late final String _viewType;
  late final web.HTMLIFrameElement _iframe;
  web.XMLHttpRequest? _request;
  String? _objectUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewType =
        'dms-pdf-viewer-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = web.HTMLIFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';

    _iframe
      ..setAttribute('title', widget.title)
      ..setAttribute('loading', 'eager')
      ..setAttribute('allowfullscreen', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _loadPdfBlob();
  }

  void _loadPdfBlob() {
    final request = web.XMLHttpRequest()
      ..open('GET', widget.url, true)
      ..responseType = 'blob';
    _request = request;

    request.onLoad.listen((web.ProgressEvent event) {
      final accepted = request.status >= 200 && request.status < 300;
      final response = request.response;

      if (!mounted) {
        return;
      }

      if (!accepted || response == null) {
        _showError();
        return;
      }

      final objectUrl = web.URL.createObjectURL(response as JSObject);
      _objectUrl = objectUrl;
      _iframe.src = objectUrl;

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    });

    request.onError.listen((web.ProgressEvent event) => _showError());
    request.send();
  }

  void _showError() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  @override
  void dispose() {
    _request?.abort();

    final objectUrl = _objectUrl;
    if (objectUrl != null) {
      web.URL.revokeObjectURL(objectUrl);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: _viewType)),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: ColorResources.primaryColor,
            ),
          ),
        if (_hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    LocalStrings.openFileFailed.tr,
                    textAlign: TextAlign.center,
                    style: mediumLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
