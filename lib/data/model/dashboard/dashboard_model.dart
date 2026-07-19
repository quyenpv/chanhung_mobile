import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/profile/profile_model.dart';
import 'package:chanhung/data/model/project/project_model.dart';

class DashboardModel {
  DashboardModel({
    bool? success,
    String? message,
    Data? data,
  }) {
    _success = success;
    _message = message;
    _data = data;
  }

  DashboardModel.fromJson(dynamic json) {
    final payload = apiPayload(json);
    _success = apiSuccess(json);
    _message = apiMessage(json);
    _data = payload['data'] != null ? Data.fromJson(payload['data']) : null;
  }
  bool? _success;
  String? _message;
  Data? _data;

  bool? get success => _success;
  String? get message => _message;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({
    WidgetsData? widgetsData,
    ClientData? clientData,
    List<String>? permissions,
    List<Project>? projects,
  }) {
    _widgetsData = widgetsData;
    _clientData = clientData;
    _permissions = permissions;
    _projects = projects;
  }

  Data.fromJson(dynamic json) {
    if (json is! Map) {
      return;
    }
    _widgetsData =
        json['widgets'] != null ? WidgetsData.fromJson(json['widgets']) : null;
    _clientData =
        json['client'] != null ? ClientData.fromJson(json['client']) : null;
    if (json['permissions'] != null) {
      _permissions = [];
      json['permissions'].forEach((v) {
        _permissions?.add(v);
      });
    }
    if (json['projects'] != null) {
      _projects = [];
      json['projects'].forEach((v) {
        _projects?.add(Project.fromJson(v));
      });
    }
  }
  WidgetsData? _widgetsData;
  ClientData? _clientData;
  List<String>? _permissions;
  List<Project>? _projects;

  WidgetsData? get widgetsData => _widgetsData;
  ClientData? get clientData => _clientData;
  List<String>? get permissions => _permissions;
  List<Project>? get projects => _projects;

  WidgetsData ensureWidgetsData() {
    _widgetsData ??= WidgetsData();
    return _widgetsData!;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (_widgetsData != null) {
      map['widgets'] = _widgetsData?.toJson();
    }

    if (_clientData != null) {
      map['client'] = _clientData?.toJson();
    }

    if (_permissions != null) {
      map['permissions'] = _permissions?.map((v) => v).toList();
    }

    if (_projects != null) {
      map['projects'] = _projects?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class WidgetsData {
  WidgetsData({
    int? projects,
    num? totalInvoiced,
    num? payments,
    num? due,
    DashboardHrStats? hr,
    DashboardDocumentStats? documents,
    DashboardSigningStats? electronicSigning,
  }) {
    _projects = projects;
    _totalInvoiced = totalInvoiced;
    _payments = payments;
    _due = due;
    _hr = hr;
    _documents = documents;
    _electronicSigning = electronicSigning;
  }

  WidgetsData.fromJson(dynamic json) {
    if (json is! Map) {
      return;
    }
    _projects = _toInt(json['project_count']);
    _totalInvoiced = _toNum(json['total_invoiced']);
    _payments = _toNum(json['payments']);
    _due = _toNum(json['due']);
    _hr = DashboardHrStats.fromJson(json['hr']);
    _documents = DashboardDocumentStats.fromJson(json['documents']);
    _electronicSigning =
        DashboardSigningStats.fromJson(json['electronic_signing']);
  }

  int? _projects;
  num? _totalInvoiced;
  num? _payments;
  num? _due;
  DashboardHrStats? _hr;
  DashboardDocumentStats? _documents;
  DashboardSigningStats? _electronicSigning;

  int? get projects => _projects;
  num? get totalInvoiced => _totalInvoiced;
  num? get payments => _payments;
  num? get due => _due;
  DashboardHrStats? get hr => _hr;
  DashboardDocumentStats? get documents => _documents;
  DashboardSigningStats? get electronicSigning => _electronicSigning;
  int get dmsAttentionCount =>
      (_documents?.unread ?? 0) + (_electronicSigning?.waitingApproval ?? 0);
  bool get needsSummaryFallback =>
      (_projects ?? 0) == 0 ||
      (_totalInvoiced ?? 0) == 0 ||
      (_payments ?? 0) == 0 ||
      (_due ?? 0) == 0;

  void applySummaryFallback({
    int? projects,
    num? totalInvoiced,
    num? payments,
    num? due,
  }) {
    if ((_projects ?? 0) == 0 && (projects ?? 0) > 0) {
      _projects = projects;
    }
    if ((_totalInvoiced ?? 0) == 0 && (totalInvoiced ?? 0) > 0) {
      _totalInvoiced = totalInvoiced;
    }
    if ((_payments ?? 0) == 0 && (payments ?? 0) > 0) {
      _payments = payments;
    }
    if ((_due ?? 0) == 0 && (due ?? 0) > 0) {
      _due = due;
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['project_count'] = _projects;
    map['total_invoiced'] = _totalInvoiced;
    map['payments'] = _payments;
    map['due'] = _due;
    map['hr'] = _hr?.toJson();
    map['documents'] = _documents?.toJson();
    map['electronic_signing'] = _electronicSigning?.toJson();
    return map;
  }
}

class DashboardHrStats {
  DashboardHrStats({
    this.totalEmployees = 0,
    this.newEmployeesThisMonth = 0,
    this.presentToday = 0,
    this.onLeaveToday = 0,
  });

  DashboardHrStats.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    totalEmployees = _toInt(map['total_employees']);
    newEmployeesThisMonth = _toInt(map['new_employees_this_month']);
    presentToday = _toInt(map['present_today']);
    onLeaveToday = _toInt(map['on_leave_today']);
  }

  int totalEmployees = 0;
  int newEmployeesThisMonth = 0;
  int presentToday = 0;
  int onLeaveToday = 0;

  Map<String, dynamic> toJson() {
    return {
      'total_employees': totalEmployees,
      'new_employees_this_month': newEmployeesThisMonth,
      'present_today': presentToday,
      'on_leave_today': onLeaveToday,
    };
  }
}

class DashboardDocumentStats {
  DashboardDocumentStats({
    this.created = 0,
    this.received = 0,
    this.sent = 0,
    this.unread = 0,
  });

  DashboardDocumentStats.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    created = _toInt(map['created']);
    received = _toInt(map['received']);
    sent = _toInt(map['sent']);
    unread = _toInt(map['unread']);
  }

  int created = 0;
  int received = 0;
  int sent = 0;
  int unread = 0;

  Map<String, dynamic> toJson() {
    return {
      'created': created,
      'received': received,
      'sent': sent,
      'unread': unread,
    };
  }
}

class DashboardSigningStats {
  DashboardSigningStats({
    this.waitingApproval = 0,
    this.waitingInitial = 0,
    this.waitingIssuance = 0,
    this.signed = 0,
  });

  DashboardSigningStats.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    waitingApproval = _toInt(map['waiting_approval']);
    waitingInitial = _toInt(map['waiting_initial']);
    waitingIssuance = _toInt(map['waiting_issuance']);
    signed = _toInt(map['signed']);
  }

  int waitingApproval = 0;
  int waitingInitial = 0;
  int waitingIssuance = 0;
  int signed = 0;

  Map<String, dynamic> toJson() {
    return {
      'waiting_approval': waitingApproval,
      'waiting_initial': waitingInitial,
      'waiting_issuance': waitingIssuance,
      'signed': signed,
    };
  }
}

class Permissions {
  Permissions({
    String? id,
  }) {
    _id = id;
  }

  Permissions.fromJson(dynamic json) {
    _id = json['id'];
  }

  String? _id;

  String? get id => _id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    return map;
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

num _toNum(dynamic value) {
  if (value is num) {
    return value;
  }
  final raw = value?.toString().trim() ?? '';
  return num.tryParse(raw.replaceAll(',', '')) ?? 0;
}
