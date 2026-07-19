import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class LeaveRepo {
  ApiClient apiClient;
  LeaveRepo({required this.apiClient});

  Future<ResponseModel> getLeaves({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.leavesUrl}')
        .replace(queryParameters: params)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> getLeaveTypes() async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.leaveTypesUrl}';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> applyLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    bool halfDay = false,
  }) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.leavesUrl}';
    final Map<String, dynamic> body = {
      'leave_type_id': leaveTypeId.toString(),
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
      'is_half_day': halfDay ? '1' : '0',
    };
    return apiClient.request(url, Method.postMethod, body, passHeader: true);
  }
}
