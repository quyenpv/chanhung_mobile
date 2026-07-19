class LeaveModel {
  final int id;
  final int applicantId;
  final String applicantName;
  final String leaveTypeName;
  final int leaveTypeId;
  final String status;
  final String reason;
  final String startDate;
  final String endDate;
  final String duration;
  final String createdAt;

  const LeaveModel({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.leaveTypeName,
    required this.leaveTypeId,
    required this.status,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.createdAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      applicantId: int.tryParse(json['applicant_id']?.toString() ?? '0') ?? 0,
      applicantName: json['applicant_name']?.toString() ?? '',
      leaveTypeName: json['leave_type_name']?.toString() ?? json['leave_type_title']?.toString() ?? '',
      leaveTypeId: int.tryParse(json['leave_type_id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class LeavesModel {
  final List<LeaveModel> leaves;
  final int total;

  const LeavesModel({required this.leaves, required this.total});

  factory LeavesModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final list = (data['leaves'] as List<dynamic>? ?? json['leaves'] as List<dynamic>? ?? [])
        .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return LeavesModel(
      leaves: list,
      total: int.tryParse(data['total']?.toString() ?? json['total']?.toString() ?? '0') ?? list.length,
    );
  }
}

class LeaveTypeModel {
  final int id;
  final String title;

  const LeaveTypeModel({required this.id, required this.title});

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
    );
  }
}
