import 'dart:async';
import 'dart:convert';
import 'package:chanhung/core/helper/currency_format_helper.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:get/get.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/model/dashboard/dashboard_model.dart';
import 'package:chanhung/data/repo/dashboard/dashboard_repo.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class DashboardController extends GetxController {
  DashboardRepo dashboardRepo;
  DashboardController({required this.dashboardRepo});

  bool isLoading = true;
  bool logoutLoading = false;
  String? appLogo;
  String? currency;
  String? currencyPosition;
  String? defaultCurrency;

  DashboardModel dashboardModel = DashboardModel();

  bool get hasDashboardData => dashboardModel.data != null;

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad ? true : false;
    update();

    if (!dashboardRepo.hasValidToken()) {
      await _redirectToLogin();
      return;
    }

    await loadData();
    appLogo = dashboardRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.appLogo);
    currency = dashboardRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencySymbol);
    currencyPosition = dashboardRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.currencyPosition);
    defaultCurrency = dashboardRepo.apiClient.sharedPreferences
        .getString(SharedPreferenceHelper.defaultCurrency);
    isLoading = false;
    update();
  }

  String formatDashboardAmount(dynamic amount) {
    return CurrencyFormatHelper.format(
      amount,
      symbol: currency,
      position: currencyPosition,
      currencyCode: defaultCurrency,
    );
  }

  Future<void> loadData() async {
    ResponseModel responseModel = await dashboardRepo.getDashboardData();
    if (responseModel.statusCode == 200) {
      try {
        dashboardModel =
            DashboardModel.fromJson(jsonDecode(responseModel.responseJson));
      } catch (_) {
        resetClientMenu();
        CustomSnackBar.error(errorList: [LocalStrings.somethingWentWrong.tr]);
        isLoading = false;
        update();
        return;
      }

      if (dashboardModel.success == true && dashboardModel.data != null) {
        await setClientMenu(dashboardModel.data?.permissions ?? []);
        await _hydrateSummaryFallback();
      } else {
        resetClientMenu();
        CustomSnackBar.error(errorList: [
          dashboardModel.message ?? LocalStrings.somethingWentWrong.tr
        ]);
      }
    } else if (responseModel.statusCode == 401 ||
        responseModel.statusCode == 403) {
      await _redirectToLogin();
      return;
    } else {
      resetClientMenu();
      CustomSnackBar.error(errorList: [responseModel.message]);
    }

    isLoading = false;
    update();
  }

  Future<void> _hydrateSummaryFallback() async {
    final data = dashboardModel.data;
    final widgetsData = data?.widgetsData;
    if (data == null ||
        widgetsData == null ||
        !widgetsData.needsSummaryFallback) {
      return;
    }

    try {
      final fallbackResults = await Future.wait<Object?>([
        _fetchProjectCountFallback(),
        _fetchInvoiceSummaryFallback(),
      ]);

      final projectCount = fallbackResults[0] as int?;
      final invoiceSummary = fallbackResults[1] as _DashboardInvoiceSummary?;

      data.ensureWidgetsData().applySummaryFallback(
            projects: projectCount,
            totalInvoiced: invoiceSummary?.totalInvoiced,
            payments: invoiceSummary?.payments,
            due: invoiceSummary?.due,
          );
    } catch (_) {}
  }

  Future<int?> _fetchProjectCountFallback() async {
    final responseModel = await dashboardRepo.getProjectsData();
    if (responseModel.statusCode != 200 || responseModel.responseJson.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(responseModel.responseJson);
    final total = _extractPaginationTotal(decoded, 'projects');
    return total > 0 ? total : null;
  }

  Future<_DashboardInvoiceSummary?> _fetchInvoiceSummaryFallback() async {
    final responseModel = await dashboardRepo.getInvoicesData();
    if (responseModel.statusCode != 200 || responseModel.responseJson.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(responseModel.responseJson);
    final invoices = apiListPayload(decoded, 'invoices');
    if (invoices.isEmpty) {
      return null;
    }

    var totalInvoiced = 0.0;
    var payments = 0.0;
    var hasAmount = false;

    for (final item in invoices) {
      if (item is! Map) {
        continue;
      }

      final invoice = Map<String, dynamic>.from(item);
      final status = invoice['status']?.toString().trim().toLowerCase() ?? '';
      if (status == 'draft' || status == 'cancelled' || status == 'credited') {
        continue;
      }

      final invoiceValue = _toDashboardNum(
        invoice['invoice_value'] ?? invoice['invoice_total'],
      );
      final paymentReceived = _toDashboardNum(invoice['payment_received']);

      if (invoiceValue > 0 || paymentReceived > 0) {
        hasAmount = true;
      }

      totalInvoiced += invoiceValue;
      payments += paymentReceived;
    }

    if (!hasAmount) {
      return null;
    }

    final due = totalInvoiced - payments;
    return _DashboardInvoiceSummary(
      totalInvoiced: totalInvoiced,
      payments: payments,
      due: due > 0 ? due : 0,
    );
  }

  int _extractPaginationTotal(dynamic decoded, String resourceKey) {
    final payload = apiPayload(decoded);
    final total = _readPaginationTotal(payload['pagination']);
    if (total != null) {
      return total;
    }

    final data = payload['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final nestedTotal = _readPaginationTotal(dataMap['pagination']);
      if (nestedTotal != null) {
        return nestedTotal;
      }
    }

    return apiListPayload(decoded, resourceKey).length;
  }

  int? _readPaginationTotal(dynamic pagination) {
    if (pagination is! Map) {
      return null;
    }
    final total = _toDashboardInt(pagination['total']);
    return total > 0 ? total : null;
  }

  int _toDashboardInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDashboardNum(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final raw = value?.toString().trim() ?? '';
    return double.tryParse(raw.replaceAll(',', '')) ?? 0;
  }

  Future<void> _redirectToLogin() async {
    await dashboardRepo.clearSharedPrefData();
    resetClientMenu();
    dashboardModel = DashboardModel();
    isLoading = false;
    update();
    if (Get.currentRoute != RouteHelper.loginScreen) {
      Get.offAllNamed(RouteHelper.loginScreen);
    }
  }

  bool isProjectsEnable = false;
  bool isContractsEnable = false;
  bool isProposalsEnable = false;
  bool isEstimatesEnable = false;
  bool isInvoicesEnable = false;
  bool isPaymentsEnable = false;
  bool isPaymentRequestsEnable = false;
  bool isTicketsEnable = false;
  bool isHumanResourcesEnable = false;
  bool isDmsOfficeEnable = false;

  void resetClientMenu() {
    isProjectsEnable = false;
    isContractsEnable = false;
    isProposalsEnable = false;
    isEstimatesEnable = false;
    isInvoicesEnable = false;
    isPaymentsEnable = false;
    isPaymentRequestsEnable = false;
    isTicketsEnable = false;
    isHumanResourcesEnable = false;
    isDmsOfficeEnable = false;
  }

  Future<void> setClientMenu(List<String> permissions) async {
    resetClientMenu();
    if (permissions.contains('all')) {
      isProjectsEnable = true;
      isContractsEnable = true;
      isProposalsEnable = true;
      isEstimatesEnable = true;
      isInvoicesEnable = true;
      isPaymentsEnable = true;
      isPaymentRequestsEnable = true;
      isTicketsEnable = true;
      isHumanResourcesEnable = true;
      isDmsOfficeEnable = true;
    } else {
      if (permissions.contains('projects')) {
        isProjectsEnable = true;
      }
      if (permissions.contains('contracts')) {
        isContractsEnable = true;
      }
      if (permissions.contains('proposals')) {
        isProposalsEnable = true;
      }
      if (permissions.contains('estimates')) {
        isEstimatesEnable = true;
      }
      if (permissions.contains('invoices')) {
        isInvoicesEnable = true;
      }
      if (permissions.contains('payments')) {
        isPaymentsEnable = true;
      }
      if (permissions.contains('payment_requests')) {
        isPaymentRequestsEnable = true;
      }
      if (permissions.contains('tickets')) {
        isTicketsEnable = true;
      }
      if (permissions.contains('users') ||
          permissions.contains('hr_dashboard') ||
          permissions.contains('hr_employees') ||
          permissions.contains('team_members')) {
        isHumanResourcesEnable = true;
      }
      if (permissions.contains('documents') ||
          permissions.contains('dms_documents') ||
          permissions.contains('dms_office')) {
        isDmsOfficeEnable = true;
      }
    }
    update();
  }

  Future<void> logout() async {
    logoutLoading = true;
    update();
    await dashboardRepo.clearSharedPrefData();
    CustomSnackBar.success(successList: [LocalStrings.logoutSuccessMsg.tr]);
    logoutLoading = false;
    update();
    Get.offAllNamed(RouteHelper.loginScreen);
  }
}

class _DashboardInvoiceSummary {
  const _DashboardInvoiceSummary({
    required this.totalInvoiced,
    required this.payments,
    required this.due,
  });

  final double totalInvoiced;
  final double payments;
  final double due;
}
