import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chanhung/core/helper/face_camera_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/hr/attendance_model.dart';
import 'package:chanhung/data/repo/hr/attendance_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class AttendanceController extends GetxController {
  final AttendanceRepo attendanceRepo;
  AttendanceController({required this.attendanceRepo});

  bool isLoading = true;
  bool isChecking = false;
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

  // ─── GPS Helper ─────────────────────────────────────────────────────────────

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CustomSnackBar.error(errorList: ['Vui lòng bật Dịch vụ Vị trí (GPS)']);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomSnackBar.error(errorList: ['Quyền truy cập vị trí bị từ chối']);
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      CustomSnackBar.error(errorList: [
        'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt.'
      ]);
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  void _resetChecking() {
    isChecking = false;
    update();
  }

  bool _isApiSuccess(ResponseModel response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      return false;
    }
    final decoded = _safeDecodeJson(response.responseJson);
    if (decoded == null) return true;
    final success = apiSuccess(decoded);
    // null = không có cờ success lồng nhau → coi HTTP 2xx là thành công
    return success != false;
  }

  String _errorMessage(ResponseModel response) {
    final decoded = _safeDecodeJson(response.responseJson);
    return apiMessage(decoded) ??
        (response.message.isNotEmpty
            ? response.message
            : LocalStrings.somethingWentWrong.tr);
  }

  // ─── CHECK-IN ────────────────────────────────────────────────────────────────

  Future<void> doCheckIn(BuildContext context) async {
    isChecking = true;
    update();

    try {
      final position = await _getLocation();
      if (position == null) {
        _resetChecking();
        return;
      }

      if (!context.mounted) {
        _resetChecking();
        return;
      }

      final selfieBase64 = await FaceCameraHelper.captureVerifiedSelfie(context);
      if (selfieBase64 == null) {
        _resetChecking();
        return;
      }

      CustomSnackBar.success(
          successList: ['Đang so khớp khuôn mặt với ảnh hồ sơ ERP...']);

      ResponseModel response = await attendanceRepo.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        selfieBase64: selfieBase64,
      );

      if (_isApiSuccess(response)) {
        final decoded = _safeDecodeJson(response.responseJson);
        final msg = apiMessage(decoded) ?? LocalStrings.checkInSuccess.tr;
        CustomSnackBar.success(successList: [msg]);
        await loadTodayStatus();
        await loadHistory();
      } else {
        CustomSnackBar.error(errorList: [_errorMessage(response)]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: ['Lỗi chấm công: ${e.toString()}']);
    }

    _resetChecking();
  }

  // ─── CHECK-OUT ───────────────────────────────────────────────────────────────

  Future<void> doCheckOut(BuildContext context) async {
    isChecking = true;
    update();

    try {
      final position = await _getLocation();
      if (position == null) {
        _resetChecking();
        return;
      }

      if (!context.mounted) {
        _resetChecking();
        return;
      }

      final selfieBase64 = await FaceCameraHelper.captureVerifiedSelfie(context);
      if (selfieBase64 == null) {
        _resetChecking();
        return;
      }

      CustomSnackBar.success(
          successList: ['Đang so khớp khuôn mặt với ảnh hồ sơ ERP...']);

      ResponseModel response = await attendanceRepo.checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
        selfieBase64: selfieBase64,
      );

      if (_isApiSuccess(response)) {
        final decoded = _safeDecodeJson(response.responseJson);
        final msg = apiMessage(decoded) ?? LocalStrings.checkOutSuccess.tr;
        CustomSnackBar.success(successList: [msg]);
        await loadTodayStatus();
        await loadHistory();
      } else {
        CustomSnackBar.error(errorList: [_errorMessage(response)]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: ['Lỗi chấm công: ${e.toString()}']);
    }

    _resetChecking();
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
