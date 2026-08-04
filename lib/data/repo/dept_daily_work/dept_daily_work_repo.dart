import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/core/utils/method.dart';

class DeptDailyWorkRepo {
  final ApiClient apiClient;

  DeptDailyWorkRepo({required this.apiClient});

  Future<dynamic> getDepartments() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.deptDailyWorkUrl}/departments';
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  Future<dynamic> getDeptDailyWork(String? departmentId) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.deptDailyWorkUrl}';
    if (departmentId != null && departmentId.isNotEmpty) {
      url += '?department_id=$departmentId';
    }
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  Future<dynamic> updateStatus(String id, String status, int progressPercent) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.deptDailyWorkUrl}/update_status';
    Map<String, dynamic> body = {
      'id': id,
      'status': status,
      'progress_percent': progressPercent,
    };
    final response = await apiClient.request(url, Method.postMethod, body, passHeader: true);
    return response;
  }
}
