import 'dart:convert';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/attendance_model.dart';
import 'package:chanhung/data/repo/hr/attendance_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class AttendanceController extends GetxController {
  final AttendanceRepo attendanceRepo;
  AttendanceController({required this.attendanceRepo});

  bool isLoading = true;
  bool isChecking = false; // loading state for check-in/out
  bool isHistoryLoading = false;

  AttendanceStatus? todayStatus;
  AttendanceHistoryModel historyModel =
      const AttendanceHistoryModel(records: [], total: 0);

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();

    await Future.wait([
      loadTodayStatus(),
      loadHistory(),
    ]);

    isLoading = false;
    update();
  }

  Future<void> loadTodayStatus() async {
    ResponseModel response = await attendanceRepo.getTodayStatus();
    if (response.statusCode == 200) {
      try {
        todayStatus =
            AttendanceStatus.fromJson(jsonDecode(response.responseJson));
      } catch (_) {
        todayStatus = null;
      }
    }
    update();
  }

  Future<void> loadHistory() async {
    isHistoryLoading = true;
    update();

    ResponseModel response = await attendanceRepo.getHistory(limit: 30);
    if (response.statusCode == 200) {
      try {
        historyModel = AttendanceHistoryModel.fromJson(
            jsonDecode(response.responseJson));
      } catch (_) {
        historyModel = const AttendanceHistoryModel(records: [], total: 0);
      }
    }

    isHistoryLoading = false;
    update();
  }

  Future<void> doCheckIn({double? lat, double? lng}) async {
    isChecking = true;
    update();

    ResponseModel response =
        await attendanceRepo.checkIn(latitude: lat, longitude: lng);

    isChecking = false;

    if (response.statusCode == 200 || response.statusCode == 201) {
      CustomSnackBar.success(successList: [LocalStrings.checkInSuccess.tr]);
      await loadTodayStatus();
      await loadHistory();
    } else {
      final decoded = _safeDecodeJson(response.responseJson);
      final msg = decoded?['message'] as String? ??
          (response.message.isNotEmpty
              ? response.message
              : LocalStrings.somethingWentWrong.tr);
      CustomSnackBar.error(errorList: [msg]);
    }
    update();
  }

  Future<void> doCheckOut({double? lat, double? lng}) async {
    isChecking = true;
    update();

    ResponseModel response =
        await attendanceRepo.checkOut(latitude: lat, longitude: lng);

    isChecking = false;

    if (response.statusCode == 200 || response.statusCode == 201) {
      CustomSnackBar.success(successList: [LocalStrings.checkOutSuccess.tr]);
      await loadTodayStatus();
      await loadHistory();
    } else {
      final decoded = _safeDecodeJson(response.responseJson);
      final msg = decoded?['message'] as String? ??
          (response.message.isNotEmpty
              ? response.message
              : LocalStrings.somethingWentWrong.tr);
      CustomSnackBar.error(errorList: [msg]);
    }
    update();
  }

  Map<String, dynamic>? _safeDecodeJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
