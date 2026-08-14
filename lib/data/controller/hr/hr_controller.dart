import 'dart:convert';

import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/employee_model.dart';
import 'package:chanhung/data/model/hr/hr_dashboard_model.dart';
import 'package:chanhung/data/repo/hr/hr_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

enum HrEmployeeFilter { all, newThisMonth, presentToday, onLeaveToday }

List<Employee> filterEmployeesByMetric(
  List<Employee> employees,
  HrEmployeeFilter filter,
  HrMetrics? metrics,
) {
  if (filter == HrEmployeeFilter.all || metrics == null) {
    return employees;
  }

  final ids = switch (filter) {
    HrEmployeeFilter.newThisMonth => metrics.newEmployeeIds,
    HrEmployeeFilter.presentToday => metrics.presentTodayIds,
    HrEmployeeFilter.onLeaveToday => metrics.onLeaveTodayIds,
    HrEmployeeFilter.all => <String>{},
  };
  return employees.where((employee) => ids.contains(employee.id)).toList();
}

class HrController extends GetxController {
  HrRepo hrRepo;
  HrController({required this.hrRepo});

  bool isLoading = true;
  bool isSearching = false;
  EmployeesModel employeesModel = EmployeesModel(data: []);
  HrDashboardModel hrDashboardModel = HrDashboardModel(units: []);
  String searchText = '';
  HrEmployeeFilter selectedFilter = HrEmployeeFilter.all;

  List<Employee> get visibleEmployees {
    final employees = filterEmployeesByMetric(
      employeesModel.data ?? [],
      selectedFilter,
      hrDashboardModel.metrics,
    );
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return employees;
    }

    return employees.where((employee) {
      final searchableFields = [
        employee.id,
        employee.fullName,
        employee.email,
        employee.phone,
        employee.jobTitle,
        employee.address,
        employee.companyName,
        employee.workType,
      ];
      return searchableFields.any(
        (value) => value?.toLowerCase().contains(query) == true,
      );
    }).toList();
  }

  void selectFilter(HrEmployeeFilter filter) {
    selectedFilter = selectedFilter == filter ? HrEmployeeFilter.all : filter;
    update();
  }

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();

    await Future.wait([
      loadHrDashboard(showError: false),
      loadEmployees(showLoader: false),
    ]);

    isLoading = false;
    update();
  }

  Future<void> loadEmployees({
    bool showLoader = true,
    bool showError = true,
  }) async {
    if (showLoader) {
      isSearching = true;
      update();
    }

    const pageSize = 100;
    final employees = <Employee>[];
    ResponseModel? failedResponse;
    var page = 1;

    while (true) {
      final responseModel =
          await hrRepo.getEmployees(search: searchText, page: page);
      if (responseModel.statusCode != 200) {
        failedResponse = responseModel;
        break;
      }

      final pageModel =
          EmployeesModel.fromJson(jsonDecode(responseModel.responseJson));
      final pageEmployees = pageModel.data ?? [];
      employees.addAll(pageEmployees);
      if (pageEmployees.length < pageSize) {
        break;
      }
      page++;
    }

    if (failedResponse == null) {
      employeesModel = EmployeesModel(data: employees);
    } else {
      employeesModel = EmployeesModel(data: []);
      if (showError) {
        CustomSnackBar.error(errorList: [
          failedResponse.message.isNotEmpty
              ? failedResponse.message
              : LocalStrings.somethingWentWrong.tr
        ]);
      }
    }

    isSearching = false;
    update();
  }

  Future<void> loadHrDashboard({bool showError = false}) async {
    ResponseModel responseModel = await hrRepo.getHrDashboard();
    if (responseModel.statusCode == 200) {
      hrDashboardModel =
          HrDashboardModel.fromJson(jsonDecode(responseModel.responseJson));
    } else if (showError) {
      CustomSnackBar.error(errorList: [responseModel.message]);
    }
    update();
  }

  Future<void> searchEmployees(String value) async {
    searchText = value.trim();
    await loadEmployees();
  }

  void filterEmployees(String value) {
    searchText = value.trim();
    update();
  }

  Future<void> clearSearch() async {
    if (searchText.isEmpty) {
      return;
    }
    searchText = '';
    await loadEmployees();
  }
}
