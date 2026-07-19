class AttendanceStatus {
  final bool checkedInToday;
  final bool checkedOutToday;
  final String? checkInTime;
  final String? checkOutTime;
  final String? totalHours;

  const AttendanceStatus({
    required this.checkedInToday,
    required this.checkedOutToday,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>?;
    return AttendanceStatus(
      checkedInToday: today?['checked_in'] == true,
      checkedOutToday: today?['checked_out'] == true,
      checkInTime: today?['check_in_time']?.toString(),
      checkOutTime: today?['check_out_time']?.toString(),
      totalHours: today?['total_hours']?.toString(),
    );
  }
}

class AttendanceRecord {
  final int id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String? totalHours;
  final String status;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.totalHours,
    required this.status,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      checkIn: json['check_in_time']?.toString(),
      checkOut: json['check_out_time']?.toString(),
      totalHours: json['total_hours']?.toString(),
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }
}

class AttendanceHistoryModel {
  final List<AttendanceRecord> records;
  final int total;

  const AttendanceHistoryModel({required this.records, required this.total});

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    final list = (json['attendance'] as List<dynamic>? ?? [])
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return AttendanceHistoryModel(
      records: list,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? list.length,
    );
  }
}
