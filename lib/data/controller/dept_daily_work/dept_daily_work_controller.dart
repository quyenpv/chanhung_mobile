import 'dart:convert';
import 'package:get/get.dart';
import 'package:chanhung/data/model/dept_daily_work/dept_daily_work_model.dart';
import 'package:chanhung/data/repo/dept_daily_work/dept_daily_work_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class DeptDailyWorkController extends GetxController {
  DeptDailyWorkRepo deptDailyWorkRepo;
  DeptDailyWorkController({required this.deptDailyWorkRepo});

  bool isLoading = true;
  List<DeptDailyWorkModel> taskList = [];
  List<DepartmentModel> departmentList = [];
  String? selectedDepartmentId;
  bool isManager = false;

  @override
  void onInit() {
    super.onInit();
    initialData();
  }

  void initialData() async {
    isLoading = true;
    update();
    await getDepartments();
    if (departmentList.isNotEmpty) {
      selectedDepartmentId = departmentList.first.id;
    }
    await loadTasks();
    isLoading = false;
    update();
  }

  Future<void> getDepartments() async {
    try {
      final response = await deptDailyWorkRepo.getDepartments();
      if (response.statusCode == 200) {
        DepartmentResponseModel model = DepartmentResponseModel.fromJson(jsonDecode(response.responseJson));
        if (model.success == true && model.data != null) {
          departmentList.clear();
          departmentList.addAll(model.data!);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }
  }

  Future<void> loadTasks() async {
    isLoading = true;
    update();
    try {
      final response = await deptDailyWorkRepo.getDeptDailyWork(selectedDepartmentId);
      if (response.statusCode == 200) {
        DeptDailyWorkResponseModel model = DeptDailyWorkResponseModel.fromJson(jsonDecode(response.responseJson));
        if (model.success == true && model.data != null) {
          taskList.clear();
          taskList.addAll(model.data!);
          isManager = model.isManager ?? false;
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }
    isLoading = false;
    update();
  }

  void changeDepartment(String id) {
    selectedDepartmentId = id;
    loadTasks();
  }

  bool isSubmitLoading = false;
  Future<void> updateStatus(String id, String status, int progress) async {
    isSubmitLoading = true;
    update();
    try {
      final response = await deptDailyWorkRepo.updateStatus(id, status, progress);
      if (response.statusCode == 200) {
        final Map<String, dynamic> res = jsonDecode(response.responseJson);
        if (res['success'] == true) {
          CustomSnackBar.success(successList: [res['message'] ?? 'Cập nhật thành công']);
          await loadTasks();
        } else {
          CustomSnackBar.error(errorList: [res['message']]);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }
    isSubmitLoading = false;
    update();
  }
}
