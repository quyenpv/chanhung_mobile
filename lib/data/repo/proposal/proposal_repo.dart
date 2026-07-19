import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class ProposalRepo {
  ApiClient apiClient;
  ProposalRepo({required this.apiClient});

  Future<ResponseModel> getAllProposals() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.proposalsUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getProposalDetails(proposalId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.proposalsUrl}/$proposalId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
