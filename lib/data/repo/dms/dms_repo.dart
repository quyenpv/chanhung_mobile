import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class DmsRepo {
  ApiClient apiClient;
  DmsRepo({required this.apiClient});

  Future<ResponseModel> getDocuments({
    String? docGroup,
    String? filter,
    String? search,
  }) async {
    final queryParameters = <String, String>{'limit': '100'};
    if (docGroup != null && docGroup.isNotEmpty) {
      queryParameters['doc_group'] = docGroup;
    }
    if (filter != null && filter.isNotEmpty) {
      queryParameters['filter'] = filter;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.documentsUrl}')
        .replace(queryParameters: queryParameters)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> getDocumentDetails(dynamic documentId) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> getSignPermission(dynamic documentId) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId/sign-permission';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> startEsign(
    dynamic documentId, {
    String signerInstruction = '',
  }) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId/esign/start';
    return apiClient.request(
      url,
      Method.postMethod,
      {'signer_instruction': signerInstruction},
      passHeader: true,
    );
  }

  Future<ResponseModel> signWithPfx(
    dynamic documentId, {
    String signerInstruction = '',
    String pfxProfileSlug = '',
    String pfxPassword = '',
  }) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId/pfx/sign';
    final body = <String, String>{
      'signer_instruction': signerInstruction,
      'pfx_profile_slug': pfxProfileSlug,
    };
    if (pfxPassword.isNotEmpty) {
      body['pfx_password'] = pfxPassword;
    }

    return apiClient.request(
      url,
      Method.postMethod,
      body,
      passHeader: true,
    );
  }

  Future<ResponseModel> rejectDocument(
    dynamic documentId, {
    required String reason,
  }) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId/reject';
    return apiClient.request(
      url,
      Method.postMethod,
      {'reason': reason},
      passHeader: true,
    );
  }

  Future<ResponseModel> getEsignStatus(String transactionId) async {
    final url =
        '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/esign/status/$transactionId';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
