import 'package:chanhung/data/model/global/api_response_payload.dart';

class EmployeesModel {
  bool? success;
  String? message;
  List<Employee>? data;

  EmployeesModel({this.success = true, this.message, this.data});

  EmployeesModel.fromJson(dynamic json) {
    success = apiSuccess(json) ?? true;
    message = apiMessage(json);
    data = apiListPayload(json, 'users')
        .map((item) => Employee.fromJson(item))
        .toList();
  }
}

class Employee {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? jobTitle;
  String? status;
  String? image;
  String? workType;
  String? address;
  String? companyName;

  Employee({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
    this.status,
    this.image,
    this.workType,
    this.address,
    this.companyName,
  });

  Employee.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    id = map['id']?.toString();
    firstName = map['first_name']?.toString();
    lastName = map['last_name']?.toString();
    email = map['email']?.toString();
    phone = map['phone']?.toString();
    jobTitle = map['job_title']?.toString();
    status = map['status']?.toString();
    image = map['image']?.toString();
    workType = map['work_type']?.toString();
    address = map['address']?.toString();
    companyName = map['company_name']?.toString() ?? map['company']?.toString();
  }

  String get fullName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? email ?? '' : name;
  }

  String get initials {
    final words = fullName
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }
}
