import 'dart:async';
import 'dart:convert';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/data/model/payment/payment_details_model.dart';
import 'package:chanhung/data/model/payment/payment_model.dart';
import 'package:chanhung/data/repo/payment/payment_repo.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class PaymentController extends GetxController {
  PaymentRepo paymentRepo;
  PaymentController({required this.paymentRepo});

  bool isLoading = true;
  PaymentsModel paymentsModel = PaymentsModel();
  PaymentDetailsModel paymentDetailsModel = PaymentDetailsModel();
  String? currency;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad ? true : false;
    update();

    await loadPayments();
    currency = paymentRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    isLoading = false;
    update();
  }

  Future<void> loadPayments() async {
    ResponseModel responseModel = await paymentRepo.getAllPayments();
    paymentsModel =
        PaymentsModel.fromJson(jsonDecode(responseModel.responseJson));
    isLoading = false;
    update();
  }

  Future<void> loadPaymentDetails(paymentId) async {
    ResponseModel responseModel =
        await paymentRepo.getPaymentDetails(paymentId);
    currency = paymentRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    if (responseModel.statusCode == 200) {
      paymentDetailsModel =
          PaymentDetailsModel.fromJson(jsonDecode(responseModel.responseJson));
    } else {
      CustomSnackBar.error(errorList: [responseModel.message]);
    }

    isLoading = false;
    update();
  }
}
