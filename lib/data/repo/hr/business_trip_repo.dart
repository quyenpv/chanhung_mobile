import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class BusinessTripRepo {
  ApiClient apiClient;
  BusinessTripRepo({required this.apiClient});

  Future<ResponseModel> getTrips({String? status, int limit = 50, int offset = 0}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final url = Uri.parse('${UrlContainer.baseUrl}${UrlContainer.businessTripsUrl}')
        .replace(queryParameters: params)
        .toString();
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> getTrip(int id) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.businessTripsUrl}/$id';
    return apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> createTrip({
    required String title,
    required String startDate,
    required String endDate,
    String destination = '',
    String purpose = '',
    String notes = '',
  }) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.businessTripsUrl}';
    final Map<String, dynamic> body = {
      'title': title,
      'start_date': startDate,
      'end_date': endDate,
      'destination': destination,
      'purpose': purpose,
      'notes': notes,
    };
    return apiClient.request(url, Method.postMethod, body, passHeader: true);
  }

  Future<ResponseModel> cancelTrip(int id) async {
    final url = '${UrlContainer.baseUrl}${UrlContainer.businessTripsUrl}/$id/cancel';
    return apiClient.request(url, Method.postMethod, null, passHeader: true);
  }
}
