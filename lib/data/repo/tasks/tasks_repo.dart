import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class TasksRepo {
  ApiClient apiClient;
  TasksRepo({required this.apiClient});

  Future<ResponseModel> getTasks({int? assignedTo, int? statusId, int limit = 100}) async {
    final params = <String, String>{
      'limit': limit.toString(),
    };
    if (assignedTo != null) params['assigned_to'] = assignedTo.toString();
    if (statusId != null) params['status_id'] = statusId.toString();

    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.tasksUrl}')
        .replace(queryParameters: params)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> updateTaskStatus(String taskId, int statusId) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.tasksUrl}/$taskId';
    final body = {
      'status_id': statusId,
    };
    return apiClient.request(url, Method.putMethod, body, passHeader: true);
  }
}
