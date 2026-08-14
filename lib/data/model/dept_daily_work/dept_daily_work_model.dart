class DeptDailyWorkResponseModel {
  bool? success;
  String? message;
  int? departmentId;
  bool? isManager;
  List<DeptDailyWorkModel>? data;

  DeptDailyWorkResponseModel({
    this.success,
    this.message,
    this.departmentId,
    this.isManager,
    this.data,
  });

  DeptDailyWorkResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapApiPayload(json);
    success = payload['success'];
    message = payload['message'];
    departmentId = payload['department_id'] != null
        ? int.tryParse(payload['department_id'].toString())
        : null;
    isManager = payload['is_manager'];
    data = _jsonObjectList(
      payload['data'],
    ).map(DeptDailyWorkModel.fromJson).toList();
  }
}

class DeptDailyWorkModel {
  String? id;
  String? title;
  String? departmentId;
  String? status;
  String? priority;
  String? startDate;
  String? deadline;
  String? completedAt;
  String? assigneeNames;
  int? progressPercent;
  String? listTitle;
  String? origin;

  DeptDailyWorkModel({
    this.id,
    this.title,
    this.departmentId,
    this.status,
    this.priority,
    this.startDate,
    this.deadline,
    this.completedAt,
    this.assigneeNames,
    this.progressPercent,
    this.listTitle,
    this.origin,
  });

  DeptDailyWorkModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    title = json['title']?.toString();
    departmentId = json['department_id']?.toString();
    status = json['status']?.toString();
    priority = json['priority']?.toString();
    startDate = json['start_date']?.toString();
    deadline = json['deadline']?.toString();
    completedAt = json['completed_at']?.toString();
    assigneeNames = json['assignee_names']?.toString();
    progressPercent = json['progress_percent'] != null
        ? int.tryParse(json['progress_percent'].toString())
        : 0;
    listTitle = json['list_title']?.toString();
    origin = json['origin']?.toString();
  }
}

class DepartmentResponseModel {
  bool? success;
  String? message;
  List<DepartmentModel>? data;

  DepartmentResponseModel({this.success, this.message, this.data});

  DepartmentResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapApiPayload(json);
    success = payload['success'];
    message = payload['message'];
    data = _jsonObjectList(
      payload['data'],
    ).map(DepartmentModel.fromJson).toList();
  }
}

class DepartmentModel {
  String? id;
  String? name;

  DepartmentModel({this.id, this.name});

  DepartmentModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = (json['name'] ?? json['title'])?.toString();
  }
}

Map<String, dynamic> _unwrapApiPayload(Map<String, dynamic> json) {
  final nested = json['data'];
  if (nested is Map && nested.containsKey('data')) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

List<Map<String, dynamic>> _jsonObjectList(dynamic value) {
  final Iterable<dynamic> entries;
  if (value is List) {
    entries = value;
  } else if (value is Map) {
    entries = value.values;
  } else {
    return const [];
  }

  return entries
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}
