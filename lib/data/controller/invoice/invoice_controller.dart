import 'dart:async';
import 'dart:convert';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/data/model/invoice/invoice_details_model.dart';
import 'package:chanhung/data/model/invoice/invoice_model.dart';
import 'package:chanhung/data/repo/invoice/invoice_repo.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class InvoiceController extends GetxController {
  InvoiceRepo invoiceRepo;
  InvoiceController({required this.invoiceRepo});

  bool isLoading = true;
  InvoicesModel invoicesModel = InvoicesModel();
  InvoiceDetailsModel invoiceDetailsModel = InvoiceDetailsModel();
  int subtotal = 0;
  String? currency;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad ? true : false;
    update();

    await loadInvoices();
    currency = invoiceRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    isLoading = false;
    update();
  }

  Future<void> loadInvoices() async {
    ResponseModel responseModel = await invoiceRepo.getAllInvoices();
    invoicesModel =
        InvoicesModel.fromJson(jsonDecode(responseModel.responseJson));
    isLoading = false;
    update();
  }

  Future<void> loadInvoiceDetails(invoiceId) async {
    ResponseModel responseModel =
        await invoiceRepo.getInvoiceDetails(invoiceId);
    currency = invoiceRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    if (responseModel.statusCode == 200) {
      invoiceDetailsModel =
          InvoiceDetailsModel.fromJson(jsonDecode(responseModel.responseJson));
      subtotal = 0;
      for (final item in invoiceDetailsModel.data?.items ?? const []) {
        subtotal += int.tryParse(item.total ?? '') ?? 0;
      }
    } else {
      CustomSnackBar.error(errorList: [responseModel.message]);
    }

    isLoading = false;
    update();
  }
}
