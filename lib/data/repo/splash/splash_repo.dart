import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class SplashRepo {
  ApiClient apiClient;
  SplashRepo({required this.apiClient});

  Future<ResponseModel> getOverviewData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.overviewUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getAppConfig() async {
    String url = "${UrlContainer.baseUrl}auth/app_config";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: false);
    return responseModel;
  }
}
