import 'package:chanhung/core/utils/method.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/services/api_service.dart';

class ProjectRepo {
  ApiClient apiClient;
  ProjectRepo({required this.apiClient});

  Future<ResponseModel> getAllProjects() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.projectsUrl}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getProjectDetails(projectId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.projectsUrl}/$projectId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getProjectTasks(projectId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.projectsUrl}/$projectId/tasks";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  Future<ResponseModel> getProjectInvoices(projectId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.projectsUrl}/$projectId/invoices";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
