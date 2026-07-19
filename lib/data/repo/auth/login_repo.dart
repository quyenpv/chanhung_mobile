import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class LoginRepo {
  ApiClient apiClient;

  LoginRepo({required this.apiClient});

  Future<ResponseModel> loginUser(String email, String password) async {
    Map<String, String> map = {'email': email, 'password': password};
    String url = '${UrlContainer.baseUrl}${UrlContainer.loginUrl}';
    ResponseModel model =
        await apiClient.request(url, Method.postMethod, map, passHeader: false);
    return model;
  }

  Future<ResponseModel> getPasskeyOptions() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.passkeyOptionsUrl}';
    ResponseModel model = await apiClient.request(
      url,
      Method.postMethod,
      <String, String>{},
      passHeader: false,
    );
    return model;
  }

  Future<ResponseModel> verifyPasskey({
    required String challengeId,
    required String responseJson,
  }) async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.passkeyVerifyUrl}';
    ResponseModel model = await apiClient.request(
      url,
      Method.postMethod,
      {
        'challenge_id': challengeId,
        'response_json': responseJson,
      },
      passHeader: false,
    );
    return model;
  }
}
