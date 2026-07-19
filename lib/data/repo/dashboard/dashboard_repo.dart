import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class DashboardRepo {
  ApiClient apiClient;
  DashboardRepo({required this.apiClient});

  Future<ResponseModel> getDashboardData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.dashboardUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getProjectsData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.projectsUrl}?limit=1";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getInvoicesData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.invoicesUrl}?limit=100";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  bool hasValidToken() {
    final token = apiClient.sharedPreferences
            .getString(SharedPreferenceHelper.accessTokenKey) ??
        '';
    final normalizedToken = token.trim().toLowerCase();
    return normalizedToken.isNotEmpty && normalizedToken != 'null';
  }

  Future<void> clearSharedPrefData() async {
    await apiClient.sharedPreferences
        .setString(SharedPreferenceHelper.userNameKey, '');
    await apiClient.sharedPreferences
        .setString(SharedPreferenceHelper.userEmailKey, '');
    await apiClient.sharedPreferences
        .remove(SharedPreferenceHelper.accessTokenType);
    await apiClient.sharedPreferences
        .remove(SharedPreferenceHelper.accessTokenKey);
    await apiClient.sharedPreferences.remove(SharedPreferenceHelper.token);
    await apiClient.sharedPreferences
        .setBool(SharedPreferenceHelper.rememberMeKey, false);
    return Future.value();
  }
}
