import 'package:chanhung/data/model/global/api_response_payload.dart';

class HrDashboardModel {
  bool? success;
  String? message;
  HrMetrics? metrics;
  List<HrUnit>? units;

  HrDashboardModel(
      {this.success = true, this.message, this.metrics, this.units});

  HrDashboardModel.fromJson(dynamic json) {
    success = apiSuccess(json) ?? true;
    message = apiMessage(json);

    final payload = apiPayload(json);
    final nested = payload['data'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : payload;

    metrics = HrMetrics.fromJson(source['metrics']);
    final unitList = source['units'];
    units = unitList is List
        ? unitList.map((item) => HrUnit.fromJson(item)).toList()
        : <HrUnit>[];
  }
}

class HrMetrics {
  int totalEmployees = 0;
  int newEmployeesThisMonth = 0;
  int presentToday = 0;
  int attendanceRate = 0;
  double averageWorkingHours = 0;
  int onLeaveToday = 0;
  Set<String> newEmployeeIds = {};
  Set<String> presentTodayIds = {};
  Set<String> onLeaveTodayIds = {};

  HrMetrics();

  HrMetrics.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    totalEmployees = _toInt(map['total_employees']);
    newEmployeesThisMonth = _toInt(map['new_employees_this_month']);
    presentToday = _toInt(map['present_today']);
    attendanceRate = _toInt(map['attendance_rate']);
    averageWorkingHours = _toDouble(map['avg_working_hours']);
    onLeaveToday = _toInt(map['on_leave_today']);
    final employeeIds = map['employee_ids'];
    final ids = employeeIds is Map
        ? Map<String, dynamic>.from(employeeIds)
        : <String, dynamic>{};
    newEmployeeIds = _toStringSet(ids['new_this_month']);
    presentTodayIds = _toStringSet(ids['present_today']);
    onLeaveTodayIds = _toStringSet(ids['on_leave_today']);
  }
}

class HrUnit {
  int id = 0;
  String name = '';
  int employeeCount = 0;

  HrUnit();

  HrUnit.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    id = _toInt(map['id']);
    name = map['name']?.toString() ?? '';
    employeeCount = _toInt(map['employee_count']);
  }
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Set<String> _toStringSet(dynamic value) {
  if (value is! List) {
    return {};
  }
  return value.map((item) => item.toString()).toSet();
}
