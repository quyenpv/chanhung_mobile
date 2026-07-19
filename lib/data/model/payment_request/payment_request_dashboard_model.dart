class PaymentRequestDashboardResponseModel {
  bool? success;
  String? message;
  PaymentRequestDashboardData? data;

  PaymentRequestDashboardResponseModel({this.success, this.message, this.data});

  PaymentRequestDashboardResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? PaymentRequestDashboardData.fromJson(json['data']) : null;
  }
}

class PaymentRequestDashboardData {
  PaymentRequestDashboardStats? stats;

  PaymentRequestDashboardData({this.stats});

  PaymentRequestDashboardData.fromJson(Map<String, dynamic> json) {
    stats = json['stats'] != null ? PaymentRequestDashboardStats.fromJson(json['stats']) : null;
  }
}

class PaymentRequestDashboardStats {
  int? totalCount;
  int? signingCount;
  int? completedCount;
  int? paidCount;
  int? rejectedCount;
  int? moreInfoCount;
  double? totalAmount;
  double? signingAmount;
  double? completedAmount;
  double? paidAmount;
  int? myCreatedCount;
  int? mySignedCount;
  bool? dashboardAccessibleOnly;
  int? signingSlaMinutes;
  int? signingOverSlaCount;
  int? mySigningOverSlaCount;
  List<DashboardChartItem>? chartData;
  List<DashboardBudgetItem>? budgetData;

  PaymentRequestDashboardStats({
    this.totalCount,
    this.signingCount,
    this.completedCount,
    this.paidCount,
    this.rejectedCount,
    this.moreInfoCount,
    this.totalAmount,
    this.signingAmount,
    this.completedAmount,
    this.paidAmount,
    this.myCreatedCount,
    this.mySignedCount,
    this.dashboardAccessibleOnly,
    this.signingSlaMinutes,
    this.signingOverSlaCount,
    this.mySigningOverSlaCount,
    this.chartData,
    this.budgetData,
  });

  PaymentRequestDashboardStats.fromJson(Map<String, dynamic> json) {
    totalCount = json['total_count'];
    signingCount = json['signing_count'];
    completedCount = json['completed_count'];
    paidCount = json['paid_count'];
    rejectedCount = json['rejected_count'];
    moreInfoCount = json['more_info_count'];
    totalAmount = json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) : 0.0;
    signingAmount = json['signing_amount'] != null ? double.tryParse(json['signing_amount'].toString()) : 0.0;
    completedAmount = json['completed_amount'] != null ? double.tryParse(json['completed_amount'].toString()) : 0.0;
    paidAmount = json['paid_amount'] != null ? double.tryParse(json['paid_amount'].toString()) : 0.0;
    myCreatedCount = json['my_created_count'];
    mySignedCount = json['my_signed_count'];
    dashboardAccessibleOnly = json['dashboard_accessible_only'] == true;
    signingSlaMinutes = json['signing_sla_minutes'];
    signingOverSlaCount = json['signing_over_sla_count'];
    mySigningOverSlaCount = json['my_signing_over_sla_count'];

    if (json['chart_data'] != null) {
      chartData = <DashboardChartItem>[];
      json['chart_data'].forEach((v) {
        chartData!.add(DashboardChartItem.fromJson(v));
      });
    }
    if (json['budget_data'] != null) {
      budgetData = <DashboardBudgetItem>[];
      json['budget_data'].forEach((v) {
        budgetData!.add(DashboardBudgetItem.fromJson(v));
      });
    }
  }
}

class DashboardChartItem {
  String? month;
  int? count;
  double? amount;

  DashboardChartItem({this.month, this.count, this.amount});

  DashboardChartItem.fromJson(Map<String, dynamic> json) {
    month = json['month']?.toString();
    count = json['count'] != null ? int.tryParse(json['count'].toString()) : 0;
    amount = json['amount'] != null ? double.tryParse(json['amount'].toString()) : 0.0;
  }
}

class DashboardBudgetItem {
  String? budgetCode;
  int? count;
  double? amount;

  DashboardBudgetItem({this.budgetCode, this.count, this.amount});

  DashboardBudgetItem.fromJson(Map<String, dynamic> json) {
    budgetCode = json['budget_code']?.toString();
    count = json['count'] != null ? int.tryParse(json['count'].toString()) : 0;
    amount = json['amount'] != null ? double.tryParse(json['amount'].toString()) : 0.0;
  }
}
