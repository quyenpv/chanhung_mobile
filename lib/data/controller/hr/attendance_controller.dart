import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chanhung/core/helper/face_camera_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
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
      CustomSnackBar.error(errorList: ['Quyền vị trí bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt.']);
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ─── CHECK-IN ────────────────────────────────────────────────────────────────

  Future<void> doCheckIn(BuildContext context) async {
    isChecking = true;
    update();

    try {
      // 1. Lấy GPS location
      final position = await _getLocation();
      if (position == null) {
        isChecking = false;
        update();
        return;
      }

      // 2. Chụp ảnh selfie + ML Kit face detection
      if (!context.mounted) return;
      final selfieBase64 = await FaceCameraHelper.captureVerifiedSelfie(context);
      if (selfieBase64 == null) {
        // User cancelled camera
        isChecking = false;
        update();
        return;
      }

      // 3. Gửi lên API
      ResponseModel response = await attendanceRepo.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        selfieBase64: selfieBase64,
      );

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
    } catch (e) {
      CustomSnackBar.error(errorList: ['Lỗi chấm công: ${e.toString()}']);
    }

    isChecking = false;
    update();
  }

  // ─── CHECK-OUT ───────────────────────────────────────────────────────────────

  Future<void> doCheckOut(BuildContext context) async {
    isChecking = true;
    update();

    try {
      // 1. Lấy GPS location
      final position = await _getLocation();
      if (position == null) {
        isChecking = false;
        update();
        return;
      }

      // 2. Chụp ảnh selfie + ML Kit face detection
      if (!context.mounted) return;
      final selfieBase64 = await FaceCameraHelper.captureVerifiedSelfie(context);
      if (selfieBase64 == null) {
        isChecking = false;
        update();
        return;
      }

      // 3. Gửi lên API
      ResponseModel response = await attendanceRepo.checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
        selfieBase64: selfieBase64,
      );

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
    } catch (e) {
      CustomSnackBar.error(errorList: ['Lỗi chấm công: ${e.toString()}']);
    }

    isChecking = false;
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
