import 'dart:convert';

import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/employee_model.dart';
import 'package:chanhung/data/model/hr/hr_dashboard_model.dart';
import 'package:chanhung/data/repo/hr/hr_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class HrController extends GetxController {
  HrRepo hrRepo;
  HrController({required this.hrRepo});

  bool isLoading = true;
  bool isSearching = false;
  EmployeesModel employeesModel = EmployeesModel(data: []);
  HrDashboardModel hrDashboardModel = HrDashboardModel(units: []);
  String searchText = '';

  List<Employee> get visibleEmployees {
    final employees = employeesModel.data ?? [];
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

    ResponseModel responseModel = await hrRepo.getEmployees(search: searchText);
    if (responseModel.statusCode == 200) {
      employeesModel =
          EmployeesModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      employeesModel = EmployeesModel(data: []);
      if (showError) {
        CustomSnackBar.error(errorList: [
          responseModel.message.isNotEmpty
              ? responseModel.message
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
