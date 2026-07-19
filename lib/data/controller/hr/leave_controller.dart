import 'dart:convert';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/leave_model.dart';
import 'package:chanhung/data/repo/hr/leave_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class LeaveController extends GetxController {
  final LeaveRepo leaveRepo;
  LeaveController({required this.leaveRepo});

  bool isLoading = true;
  bool isSubmitting = false;

  LeavesModel leavesModel = const LeavesModel(leaves: [], total: 0);
  List<LeaveTypeModel> leaveTypes = [];
  String selectedStatus = '';

  final List<Map<String, String>> statusFilters = [
    {'label': 'Tất Cả', 'value': ''},
    {'label': LocalStrings.pending, 'value': 'pending'},
    {'label': LocalStrings.approved, 'value': 'approved'},
    {'label': LocalStrings.rejected, 'value': 'rejected'},
  ];
  int selectedFilterIndex = 0;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();

    await Future.wait([
      loadLeaves(),
      loadLeaveTypes(),
    ]);

    isLoading = false;
    update();
  }

  Future<void> loadLeaves() async {
    ResponseModel response = await leaveRepo.getLeaves(
      status: selectedStatus,
      limit: 100,
    );
    if (response.statusCode == 200) {
      try {
        leavesModel = LeavesModel.fromJson(jsonDecode(response.responseJson));
      } catch (_) {
        leavesModel = const LeavesModel(leaves: [], total: 0);
      }
    } else {
      leavesModel = const LeavesModel(leaves: [], total: 0);
    }
    update();
  }

  Future<void> loadLeaveTypes() async {
    ResponseModel response = await leaveRepo.getLeaveTypes();
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.responseJson);
        final data = decoded['data'];
        List<dynamic> list = [];
        if (decoded['leave_types'] is List) {
          list = decoded['leave_types'] as List<dynamic>;
        } else if (data is Map && data['leave_types'] is List) {
          list = data['leave_types'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        }
        leaveTypes = list
            .map((e) => LeaveTypeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        leaveTypes = [];
      }
    }
    update();
  }

  void setFilter(int index) {
    selectedFilterIndex = index;
    selectedStatus = statusFilters[index]['value'] ?? '';
    update();
    loadLeaves();
  }

  Future<bool> applyLeave({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    bool halfDay = false,
  }) async {
    isSubmitting = true;
    update();

    ResponseModel response = await leaveRepo.applyLeave(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      halfDay: halfDay,
    );

    isSubmitting = false;
    update();

    if (response.statusCode == 201 || response.statusCode == 200) {
      CustomSnackBar.success(successList: [LocalStrings.leaveSubmitted.tr]);
      await loadLeaves();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }

  Future<bool> approveLeave(int leaveId) async {
    isSubmitting = true;
    update();

    ResponseModel response = await leaveRepo.approveLeave(leaveId);

    isSubmitting = false;
    update();

    if (response.statusCode == 200) {
      CustomSnackBar.success(successList: ['Duyệt đơn nghỉ phép thành công']);
      await loadLeaves();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }

  Future<bool> rejectLeave(int leaveId) async {
    isSubmitting = true;
    update();

    ResponseModel response = await leaveRepo.rejectLeave(leaveId);

    isSubmitting = false;
    update();

    if (response.statusCode == 200) {
      CustomSnackBar.success(successList: ['Từ chối đơn nghỉ phép thành công']);
      await loadLeaves();
      return true;
    } else {
      CustomSnackBar.error(errorList: [
        response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr
      ]);
      return false;
    }
  }
}

