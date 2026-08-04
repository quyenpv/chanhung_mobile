import 'dart:convert';
import 'package:get/get.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/project/tasks_model.dart';
import 'package:chanhung/data/repo/tasks/tasks_repo.dart';
import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class TasksController extends GetxController {
  final TasksRepo tasksRepo;
  TasksController({required this.tasksRepo});

  bool isLoading = true;
  bool isSubmitting = false;
  List<Task> tasksList = [];

  // Status mapping
  final List<Map<String, String>> statusFilters = [
    {'id': '', 'label': 'Tất Cả'},
    {'id': '1', 'label': 'To Do'},
    {'id': '2', 'label': 'In Progress'},
    {'id': '3', 'label': 'Done'},
  ];
  int selectedFilterIndex = 0;

  Future<void> initialData() async {
    isLoading = true;
    update();
    await loadMyTasks();
    isLoading = false;
    update();
  }

  Future<void> loadMyTasks() async {
    final dashboardController = Get.find<DashboardController>();
    final userIdStr =
        dashboardController.dashboardModel.data?.clientData?.clientId;
    final userId = int.tryParse(userIdStr ?? '');

    if (userId == null) {
      tasksList = [];
      update();
      return;
    }

    final safeFilterIndex =
        selectedFilterIndex >= 0 && selectedFilterIndex < statusFilters.length
            ? selectedFilterIndex
            : 0;
    final statusId = statusFilters[safeFilterIndex]['id'] ?? '';
    final statId = statusId.isNotEmpty ? int.tryParse(statusId) : null;

    ResponseModel response = await tasksRepo.getTasks(
      assignedTo: userId,
      statusId: statId,
    );

    if (response.statusCode == 200) {
      try {
        final tasksModel =
            TasksModel.fromJson(jsonDecode(response.responseJson));
        tasksList = tasksModel.data ?? [];
      } catch (_) {
        tasksList = [];
      }
    } else {
      tasksList = [];
    }
    update();
  }

  void setFilter(int index) {
    if (index < 0 || index >= statusFilters.length) return;
    selectedFilterIndex = index;
    update();
    loadMyTasks();
  }

  Future<bool> updateStatus(String taskId, int statusId) async {
    isSubmitting = true;
    update();

    ResponseModel response = await tasksRepo.updateTaskStatus(taskId, statusId);

    isSubmitting = false;
    update();

    if (response.statusCode == 200) {
      CustomSnackBar.success(
          successList: ['Cập nhật trạng thái công việc thành công']);
      await loadMyTasks();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : 'Không thể cập nhật trạng thái'
      ]);
      return false;
    }
  }
}
