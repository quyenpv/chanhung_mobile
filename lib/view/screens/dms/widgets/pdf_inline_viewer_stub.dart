import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:chanhung/core/helper/external_url_helper.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/services/api_service.dart';

/// Mobile/desktop: dùng flutter_pdfview (PdfRenderer native).
/// Syncfusion thường crash native với PDF đã ký số — không dùng ở đây.
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
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;
  int? _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
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
      _pdfBytes = null;
      _pages = null;
      _currentPage = 0;
    });

    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: _headers(),
      );
      final bytes = response.bodyBytes;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_messageFromBody(bytes, response.statusCode));
      }
      if (bytes.isEmpty) {
        throw Exception('File rỗng (0 byte).');
      }
      if (!_looksLikePdf(bytes)) {
        throw Exception(_messageFromBody(bytes, response.statusCode));
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _pdfBytes = null;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
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

  Widget _errorView() {
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
              _errorMessage ?? LocalStrings.openFileFailed.tr,
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
                OutlinedButton.icon(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorResources.primaryColor,
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return _errorView();
    }

    return Stack(
      children: [
        PDFView(
          pdfData: _pdfBytes,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            if (!mounted) {
              return;
            }
            setState(() {
              _pages = pages;
            });
          },
          onError: (error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _errorMessage = error?.toString().trim().isNotEmpty == true
                  ? error.toString()
                  : LocalStrings.openFileFailed.tr;
              _pdfBytes = null;
            });
          },
          onPageError: (page, error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _errorMessage =
                  'Lỗi trang ${page ?? '?'}: ${error ?? LocalStrings.openFileFailed.tr}';
              _pdfBytes = null;
            });
          },
          onPageChanged: (page, total) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPage = page ?? 0;
              _pages = total;
            });
          },
        ),
        if (_pages != null && _pages! > 0)
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${_currentPage + 1}/$_pages',
                  style: regularSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            child: IconButton(
              tooltip: LocalStrings.openInBrowser.tr,
              onPressed: _openInNewTab,
              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
