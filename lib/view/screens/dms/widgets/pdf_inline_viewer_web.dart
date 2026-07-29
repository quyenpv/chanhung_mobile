import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:chanhung/core/helper/external_url_helper.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/services/api_service.dart';

/// Web: dùng PDF viewer của trình duyệt (iframe + blob).
/// Syncfusion trên web thường lỗi với PDF đã ký số.
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
  bool _isLoading = true;
  String? _errorMessage;
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    _viewType =
        'dms-pdf-viewer-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    _iframe = web.HTMLIFrameElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('title', widget.title)
      ..setAttribute('allow', 'fullscreen');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _loadPdf();
  }

  @override
  void dispose() {
    _revokeBlob();
    super.dispose();
  }

  void _revokeBlob() {
    final blobUrl = _blobUrl;
    if (blobUrl != null && blobUrl.isNotEmpty) {
      web.URL.revokeObjectURL(blobUrl);
      _blobUrl = null;
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/pdf,application/octet-stream,*/*',
    };
    try {
      final prefs = Get.find<ApiClient>().sharedPreferences;
      final token =
          prefs.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
      final tokenType =
          prefs.getString(SharedPreferenceHelper.accessTokenType) ?? 'Bearer';
      if (token.trim().isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
        headers['X-Auth-Token'] = token;
      }
    } catch (_) {}
    return headers;
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Thử tải byte (hiển thị lỗi API rõ nếu không phải PDF).
      http.Response? response;
      Object? fetchError;
      try {
        response = await http.get(
          Uri.parse(widget.url),
          headers: _headers(),
        );
      } catch (e) {
        fetchError = e;
      }

      if (response != null) {
        final bytes = response.bodyBytes;
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            bytes.isNotEmpty &&
            _looksLikePdf(bytes)) {
          _showBlob(bytes);
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        }

        // Response không phải PDF → hiện lỗi cụ thể, vẫn cho mở tab.
        final message = response.statusCode >= 200 && response.statusCode < 300
            ? _messageFromBody(bytes, response.statusCode)
            : _messageFromBody(bytes, response.statusCode);
        throw Exception(message);
      }

      // 2) Fetch lỗi CORS/network → fallback iframe URL trực tiếp.
      if (fetchError != null) {
        _iframe.src = widget.url;
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showBlob(Uint8List bytes) {
    final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    _revokeBlob();
    _blobUrl = objectUrl;
    _iframe.src = objectUrl;
  }

  bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 5) {
      return false;
    }
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D;
  }

  String _messageFromBody(Uint8List bytes, int statusCode) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) {
      return 'Không tải được file (HTTP $statusCode).';
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] != null) {
          return '${error['message']} (HTTP $statusCode)';
        }
        if (decoded['message'] != null) {
          return '${decoded['message']} (HTTP $statusCode)';
        }
      }
    } catch (_) {}
    if (text.length > 180) {
      return 'Máy chủ không trả về PDF hợp lệ (HTTP $statusCode).';
    }
    return '$text (HTTP $statusCode)';
  }

  Future<void> _openInNewTab() async {
    await openExternalUrl(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
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
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: regularSmall.copyWith(
                  color: ColorResources.blueGreyColor,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadPdf,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(LocalStrings.retry.tr),
                  ),
                  FilledButton.icon(
                    onPressed: _openInNewTab,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(LocalStrings.openInBrowser.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: HtmlElementView(viewType: _viewType)),
        if (_isLoading)
          const ColoredBox(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                color: ColorResources.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
