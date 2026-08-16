import 'dart:async';
import 'dart:convert';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/invoice/invoice_model.dart';
import 'package:chanhung/data/model/project/project_dashboard_model.dart';
import 'package:chanhung/data/model/project/project_details_model.dart';
import 'package:chanhung/data/model/project/project_model.dart';
import 'package:chanhung/data/model/project/tasks_model.dart';
import 'package:chanhung/data/repo/project/project_repo.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class ProjectController extends GetxController {
  ProjectRepo projectRepo;
  ProjectController({required this.projectRepo});

  bool isLoading = true;
  bool isDashboardLoading = true;
  bool isTasksLoading = true;
  bool isInvoicesLoading = true;
  ProjectsModel projectsModel = ProjectsModel();
  ProjectDashboardModel dashboardModel = ProjectDashboardModel();
  ProjectDetailsModel projectDetailsModel = ProjectDetailsModel();
  TasksModel tasksModel = TasksModel();
  InvoicesModel invoicesModel = InvoicesModel();
  String? currency;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad ? true : false;
    isDashboardLoading = shouldLoad ? true : false;
    update();

    await Future.wait([
      loadDashboard(),
      loadProjects(),
    ]);
    currency = projectRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    isLoading = false;
    isDashboardLoading = false;
    update();
  }

  Future<void> loadDashboard() async {
    ResponseModel responseModel = await projectRepo.getProjectDashboard();
    if (responseModel.statusCode == 200 &&
        responseModel.responseJson.isNotEmpty) {
      dashboardModel = ProjectDashboardModel.fromJson(
          jsonDecode(responseModel.responseJson));
    }
    isDashboardLoading = false;
    update();
  }

  Future<void> loadProjects() async {
    ResponseModel responseModel = await projectRepo.getAllProjects();
    if (responseModel.statusCode == 200) {
      projectsModel =
          ProjectsModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      projectsModel = ProjectsModel(data: []);
      CustomSnackBar.error(errorList: [
        responseModel.message.isNotEmpty
            ? responseModel.message
            : LocalStrings.somethingWentWrong.tr
      ]);
    }

    isLoading = false;
    update();
  }

  Future<void> loadProjectDetails(projectId) async {
    ResponseModel responseModel =
        await projectRepo.getProjectDetails(projectId);
    currency = projectRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    if (responseModel.statusCode == 200) {
      projectDetailsModel =
          ProjectDetailsModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      CustomSnackBar.error(errorList: [responseModel.message]);
    }

    isLoading = false;
    update();
  }

  Future<void> loadProjectTasks(projectId) async {
    isTasksLoading = true;
    update();
    ResponseModel responseModel = await projectRepo.getProjectTasks(projectId);
    if (responseModel.statusCode == 200) {
      tasksModel = TasksModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      tasksModel = TasksModel(data: []);
    }
    isTasksLoading = false;
    update();
  }

  Future<void> loadProjectInvoices(projectId) async {
    isInvoicesLoading = true;
    update();
    ResponseModel responseModel =
        await projectRepo.getProjectInvoices(projectId);
    if (responseModel.statusCode == 200) {
      invoicesModel =
          InvoicesModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      invoicesModel = InvoicesModel(data: []);
    }
    isInvoicesLoading = false;
    update();
  }

  bool get hasProjects =>
      (projectsModel.success == true) &&
      (projectsModel.data?.isNotEmpty ?? false);
}
