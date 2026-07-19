import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class ForgotPasswordRepo {
  ApiClient apiClient;

  ForgotPasswordRepo({required this.apiClient});

  Future<ResponseModel> forgetPassword(String email) async {
    Map<String, String> map = {'email': email};
    String url = '${UrlContainer.baseUrl}${UrlContainer.forgotPasswordUrl}';
    ResponseModel model =
        await apiClient.request(url, Method.postMethod, map, passHeader: false);
    return model;
  }
}
