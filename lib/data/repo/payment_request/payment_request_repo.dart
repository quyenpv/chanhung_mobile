import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class PaymentRequestsRepo {
  ApiClient apiClient;
  PaymentRequestsRepo({required this.apiClient});

  Future<ResponseModel> getPaymentRequests({
    required String type,
    int limit = 50,
    int offset = 0,
    String? status,
    String? search,
  }) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}?request_type=$type&limit=$limit&offset=$offset";
    if (status != null && status.isNotEmpty) {
      url += "&status=$status";
    }
    if (search != null && search.isNotEmpty) {
      url += "&search=${Uri.encodeComponent(search)}";
    }
    ResponseModel responseModel = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getPaymentRequestDetails(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/$id";
    ResponseModel responseModel = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getDashboardStats() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/dashboard";
    ResponseModel responseModel = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getSignPermission(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/$id/sign-permission";
    ResponseModel responseModel = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> signWithPfx(int id, String slug, String password, String instruction, String keyword) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/$id/pfx/sign";
    Map<String, dynamic> body = {
      'pfx_profile_slug': slug,
      'pfx_password': password,
      'signer_instruction': instruction,
      'comment_keyword': keyword,
    };
    ResponseModel responseModel = await apiClient.request(url, Method.postMethod, body, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> startESign(int id, String instruction, String keyword) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/$id/esign/start";
    Map<String, dynamic> body = {
      'signer_instruction': instruction,
      'comment_keyword': keyword,
    };
    ResponseModel responseModel = await apiClient.request(url, Method.postMethod, body, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> checkESignStatus(String txId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.paymentRequestsUrl}/esign/status/$txId";
    ResponseModel responseModel = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
