import 'dart:convert';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/data/model/payment_request/payment_request_dashboard_model.dart';
import 'package:chanhung/data/model/payment_request/payment_request_model.dart';
import 'package:chanhung/data/repo/payment_request/payment_request_repo.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';
import 'package:get/get.dart';

class PaymentRequestsController extends GetxController {
  PaymentRequestsRepo repo;
  PaymentRequestsController({required this.repo});

  bool isLoading = true;
  bool isListLoading = false;
  bool isDetailsLoading = false;
  bool isSigning = false;

  PaymentRequestDashboardStats? dashboardStats;
  List<PaymentRequestModel> paymentRequests = [];
  List<PaymentRequestModel> settlements = [];
  PaymentRequestDetailModel? details;
  String? currency;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad ? true : false;
    update();

    currency = repo.apiClient.sharedPreferences.getString(SharedPreferenceHelper.currencySymbol) ?? 'đ';
    await loadDashboardStats();
    await loadPaymentRequests();
    await loadSettlements();

    isLoading = false;
    update();
  }

  Future<void> loadDashboardStats() async {
    try {
      ResponseModel responseModel = await repo.getDashboardStats();
      if (responseModel.statusCode == 200) {
        var res = PaymentRequestDashboardResponseModel.fromJson(jsonDecode(responseModel.responseJson));
        if (res.success == true) {
          dashboardStats = res.data?.stats;
        }
      }
    } catch (e) {
      // Quietly ignore dashboard errors to load lists
    }
  }

  Future<void> loadPaymentRequests({bool reload = false}) async {
    if (reload) {
      isListLoading = true;
      update();
    }
    try {
      ResponseModel responseModel = await repo.getPaymentRequests(type: 'payment');
      if (responseModel.statusCode == 200) {
        var res = PaymentRequestsResponseModel.fromJson(jsonDecode(responseModel.responseJson));
        if (res.success == true) {
          paymentRequests = res.data?.paymentRequests ?? [];
        }
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }
    isListLoading = false;
    update();
  }

  Future<void> loadSettlements({bool reload = false}) async {
    if (reload) {
      isListLoading = true;
      update();
    }
    try {
      ResponseModel responseModel = await repo.getPaymentRequests(type: 'advance_settlement');
      if (responseModel.statusCode == 200) {
        var res = PaymentRequestsResponseModel.fromJson(jsonDecode(responseModel.responseJson));
        if (res.success == true) {
          settlements = res.data?.paymentRequests ?? [];
        }
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }
    isListLoading = false;
    update();
  }

  Future<void> loadDetails(int id) async {
    isDetailsLoading = true;
    details = null;
    update();

    try {
      ResponseModel responseModel = await repo.getPaymentRequestDetails(id);
      if (responseModel.statusCode == 200) {
        var res = PaymentRequestDetailResponseModel.fromJson(jsonDecode(responseModel.responseJson));
        if (res.success == true) {
          details = res.data?.paymentRequest;
        } else {
          CustomSnackBar.error(errorList: [res.message ?? 'Lỗi không xác định']);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [e.toString()]);
    }

    isDetailsLoading = false;
    update();
  }

  Future<bool> submitPfxSignature(int id, String slug, String password, String instruction, String keyword) async {
    isSigning = true;
    update();

    try {
      ResponseModel responseModel = await repo.signWithPfx(id, slug, password, instruction, keyword);
      var res = jsonDecode(responseModel.responseJson);
      isSigning = false;
      update();

      if (responseModel.statusCode == 200 && res['success'] == true) {
        CustomSnackBar.success(successList: [res['message'] ?? 'Ký số thành công!']);
        loadDetails(id); // Reload details
        loadDashboardStats(); // Refresh stats
        return true;
      } else {
        CustomSnackBar.error(errorList: [res['message'] ?? 'Lỗi ký số.']);
        return false;
      }
    } catch (e) {
      isSigning = false;
      update();
      CustomSnackBar.error(errorList: [e.toString()]);
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitESignSignature(int id, String instruction, String keyword) async {
    isSigning = true;
    update();

    try {
      ResponseModel responseModel = await repo.startESign(id, instruction, keyword);
      var res = jsonDecode(responseModel.responseJson);
      isSigning = false;
      update();

      if (responseModel.statusCode == 200 && res['success'] == true) {
        return {
          'success': true,
          'transaction_id': res['transaction_id'],
          'message': res['message'],
        };
      } else {
        CustomSnackBar.error(errorList: [res['message'] ?? 'Lỗi ký eSign.']);
        return null;
      }
    } catch (e) {
      isSigning = false;
      update();
      CustomSnackBar.error(errorList: [e.toString()]);
      return null;
    }
  }

  Future<String> checkESignStatus(String txId) async {
    try {
      ResponseModel responseModel = await repo.checkESignStatus(txId);
      var res = jsonDecode(responseModel.responseJson);
      if (responseModel.statusCode == 200 && res['success'] == true) {
        return res['status'] ?? 'PENDING';
      }
      return 'FAILED';
    } catch (e) {
      return 'FAILED';
    }
  }
}
