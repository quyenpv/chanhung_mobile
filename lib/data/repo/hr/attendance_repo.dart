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

  Future<ResponseModel> checkIn({double? latitude, double? longitude, String? note}) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.attendanceCheckInUrl}';
    final Map<String, dynamic> body = {};
    if (latitude != null) body['latitude'] = latitude.toString();
    if (longitude != null) body['longitude'] = longitude.toString();
    if (note != null && note.isNotEmpty) body['note'] = note;
    return apiClient.request(url, Method.postMethod, body.isEmpty ? null : body, passHeader: true);
  }

  Future<ResponseModel> checkOut({double? latitude, double? longitude, String? note}) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.attendanceCheckOutUrl}';
    final Map<String, dynamic> body = {};
    if (latitude != null) body['latitude'] = latitude.toString();
    if (longitude != null) body['longitude'] = longitude.toString();
    if (note != null && note.isNotEmpty) body['note'] = note;
    return apiClient.request(url, Method.postMethod, body.isEmpty ? null : body, passHeader: true);
  }

  Future<ResponseModel> getHistory({int limit = 30, int offset = 0}) async {
    final params = {'limit': limit.toString(), 'offset': offset.toString()};
    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.attendanceHistoryUrl}')
        .replace(queryParameters: params)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
