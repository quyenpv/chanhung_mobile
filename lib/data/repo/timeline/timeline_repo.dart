import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class TimelineRepo {
  final ApiClient apiClient;
  TimelineRepo({required this.apiClient});

  Future<ResponseModel> feed() => apiClient.request(
      '${UrlContainer.baseUrl}timeline/feed', Method.getMethod, null,
      passHeader: true);

  Future<ResponseModel> create(String description) => apiClient.request(
      '${UrlContainer.baseUrl}timeline/create',
      Method.postMethod,
      {'description': description},
      passHeader: true);

  Future<ResponseModel> react(int postId, String emoji) => apiClient.request(
      '${UrlContainer.baseUrl}timeline/react',
      Method.postMethod,
      {'post_id': '$postId', 'emoji': emoji},
      passHeader: true);
}
