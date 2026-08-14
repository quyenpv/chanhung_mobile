import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class HrRepo {
  ApiClient apiClient;
  HrRepo({required this.apiClient});

  Future<ResponseModel> getEmployees({String? search, int page = 1}) async {
    final queryParameters = <String, String>{
      'user_type': 'staff',
      'status': 'active',
      'limit': '100',
      'page': page.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.usersUrl}')
        .replace(queryParameters: queryParameters)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> getHrDashboard() async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.hrDashboardUrl}';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
