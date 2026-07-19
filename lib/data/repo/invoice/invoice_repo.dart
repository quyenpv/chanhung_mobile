import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class InvoiceRepo {
  ApiClient apiClient;
  InvoiceRepo({required this.apiClient});

  Future<ResponseModel> getAllInvoices() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.invoicesUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getInvoiceDetails(invoiceId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.invoicesUrl}/$invoiceId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
