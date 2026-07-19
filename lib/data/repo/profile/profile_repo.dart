import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class ProfileRepo {
  ApiClient apiClient;
  ProfileRepo({required this.apiClient});

  Future<ResponseModel> getProfileData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.profileUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
