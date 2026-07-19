class BusinessTripModel {
  final int id;
  final int userId;
  final String memberName;
  final String companyName;
  final String title;
  final String destination;
  final String purpose;
  final String startDate;
  final String endDate;
  final double? totalDays;
  final double? advanceAmount;
  final double? totalAmount;
  final String status;
  final String notes;
  final String createdAt;

  const BusinessTripModel({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.companyName,
    required this.title,
    required this.destination,
    required this.purpose,
    required this.startDate,
    required this.endDate,
    this.totalDays,
    this.advanceAmount,
    this.totalAmount,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  factory BusinessTripModel.fromJson(Map<String, dynamic> json) {
    return BusinessTripModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      memberName: json['member_name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDays: double.tryParse(json['total_days']?.toString() ?? ''),
      advanceAmount: double.tryParse(json['advance_amount']?.toString() ?? ''),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class BusinessTripsModel {
  final List<BusinessTripModel> trips;
  final int total;

  const BusinessTripsModel({required this.trips, required this.total});

  factory BusinessTripsModel.fromJson(Map<String, dynamic> json) {
    final list = (json['business_trips'] as List<dynamic>? ?? [])
        .map((e) => BusinessTripModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return BusinessTripsModel(
      trips: list,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? list.length,
    );
  }
}
