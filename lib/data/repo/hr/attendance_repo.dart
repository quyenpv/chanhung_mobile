import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class AttendanceRepo {
  ApiClient apiClient;
  AttendanceRepo({required this.apiClient});

  Future<ResponseModel> getTodayStatus() async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.attendanceTodayUrl}';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> checkIn({
    required double latitude,
    required double longitude,
    String? selfieBase64,
    String? note,
  }) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.attendanceCheckInUrl}';
    final Map<String, dynamic> body = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (selfieBase64 != null && selfieBase64.isNotEmpty) {
      body['selfie_base64'] = selfieBase64;
    }
    if (note != null && note.isNotEmpty) body['note'] = note;
    return apiClient.request(url, Method.postMethod, body, passHeader: true);
  }

  Future<ResponseModel> checkOut({
    required double latitude,
    required double longitude,
    String? selfieBase64,
    String? note,
  }) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.attendanceCheckOutUrl}';
    final Map<String, dynamic> body = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
    if (selfieBase64 != null && selfieBase64.isNotEmpty) {
      body['selfie_base64'] = selfieBase64;
    }
    if (note != null && note.isNotEmpty) body['note'] = note;
    return apiClient.request(url, Method.postMethod, body, passHeader: true);
  }

  Future<ResponseModel> getHistory({int limit = 30, int offset = 0}) async {
    final params = {'limit': limit.toString(), 'offset': offset.toString()};
    final url =
        Uri.parse('${UrlContainer.baseUrl}${UrlContainer.attendanceHistoryUrl}')
            .replace(queryParameters: params)
            .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
