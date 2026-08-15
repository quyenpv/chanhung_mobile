import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dịch vụ tải và cài đặt cập nhật ứng dụng trực tiếp (In-App OTA Auto-Updater)
class OtaUpdateService {
  static final RxDouble progress = 0.0.obs; // 0.0 -> 1.0
  static final RxString statusText = ''.obs;
  static final RxString sizeText = ''.obs;
  static final RxBool isDownloading = false.obs;
  static final RxBool isCompleted = false.obs;
  static final RxString errorMessage = ''.obs;

  static http.Client? _client;

  /// Bắt đầu tải và tự động gọi trình cài đặt hệ thống Android
  static Future<void> startDownloadAndInstall({
    required String downloadUrl,
    required String targetVersion,
    VoidCallback? onStarted,
    VoidCallback? onFinished,
    Function(String error)? onError,
  }) async {
    if (isDownloading.value) return;

    isDownloading.value = true;
    isCompleted.value = false;
    progress.value = 0.0;
    statusText.value = 'Đang chuẩn bị tải gói cập nhật...';
    sizeText.value = '';
    errorMessage.value = '';
    onStarted?.call();

    try {
      if (!Platform.isAndroid) {
        // Trên iOS hoặc nền tảng khác: mở trình duyệt
        final uri = Uri.parse(downloadUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        isDownloading.value = false;
        return;
      }

      final uri = Uri.parse(downloadUrl.trim());
      _client = http.Client();

      final request = http.Request('GET', uri);
      request.headers['User-Agent'] = 'ChanHung-ERP-Mobile-OTA';

      final streamedResponse = await _client!.send(request);

      if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 302 && streamedResponse.statusCode != 301) {
        throw 'Máy chủ trả về mã lỗi ${streamedResponse.statusCode}';
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final sanitizedVer = targetVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final filePath = '${tempDir.path}/chanhung_update_$sanitizedVer.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      int receivedBytes = 0;
      DateTime lastUpdate = DateTime.now();

      statusText.value = 'Đang tải bản cập nhật v$targetVersion...';

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds > 80 || receivedBytes == totalBytes) {
          lastUpdate = now;
          if (totalBytes > 0) {
            progress.value = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            final pct = (progress.value * 100).toInt();
            sizeText.value = '$recMb MB / $totMb MB ($pct%)';
          } else {
            final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            sizeText.value = '$recMb MB';
          }
        }
      }

      await sink.flush();
      await sink.close();

      progress.value = 1.0;
      isCompleted.value = true;
      statusText.value = 'Tải hoàn tất! Đang khởi chạy trình cài đặt...';

      await Future.delayed(const Duration(milliseconds: 400));

      // Mở file APK bằng Package Installer của Android
      final openResult = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (openResult.type != ResultType.done) {
        debugPrint('[OTA] OpenFilex result: ${openResult.type} - ${openResult.message}');
        // Fallback: Nếu không mở được, thử launchUrl với external
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      onFinished?.call();
    } catch (e) {
      debugPrint('[OTA Update Error] $e');
      errorMessage.value = e.toString();
      statusText.value = 'Lỗi tải bản cập nhật: $e';
      onError?.call(e.toString());

      // Fallback sang mở trình duyệt nếu có lỗi
      try {
        final uri = Uri.parse(downloadUrl.trim());
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } finally {
      isDownloading.value = false;
      _client?.close();
      _client = null;
    }
  }

  /// Huỷ tải nếu cần
  static void cancel() {
    _client?.close();
    _client = null;
    isDownloading.value = false;
    statusText.value = 'Đã huỷ tải cập nhật.';
  }
}
