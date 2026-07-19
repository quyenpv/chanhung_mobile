import 'package:chanhung/data/model/global/api_response_payload.dart';

class LoginModel {
  LoginModel({
    bool? success,
    String? message,
    Data? data,
  }) {
    _success = success;
    _message = message;
    _data = data;
  }

  LoginModel.fromJson(dynamic json) {
    final payload = apiPayload(json);
    _success = apiSuccess(json);
    _message = apiMessage(json) ?? '';
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
    String? accessToken,
    String? clientId,
    String? companyName,
    String? firstName,
    String? lastName,
    String? type,
    String? address,
    String? email,
    dynamic permissions,
  }) {
    _token = accessToken;
    _clientId = clientId;
    _companyName = companyName;
    _firstName = firstName;
    _lastName = lastName;
    _type = type;
    _address = address;
    _email = email;
    _permissions = permissions;
  }

  Data.fromJson(dynamic json) {
    if (json is! Map) {
      return;
    }
    _token = json['token'];
    _clientId = json['client_id']?.toString();
    _type = json['user_type'];

    if (json['user_info'] != null) {
      var userInfo = json['user_info'];
      _companyName = userInfo['company_name'];
      _firstName = userInfo['first_name'];
      _lastName = userInfo['last_name'];
      _address = userInfo['address'];
      _email = userInfo['email'];
    }

    if (json['permissions'] != null) {
      _permissions = [];
      _permissionsRaw = json['permissions'];
    }
  }
  String? _token;
  String? _clientId;
  String? _companyName;
  String? _firstName;
  String? _lastName;
  String? _type;
  String? _address;
  String? _email;
  List<String>? _permissions;
  dynamic _permissionsRaw;

  String? get token => _token;
  String? get clientId => _clientId;
  String? get companyName => _companyName;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get type => _type;
  String? get address => _address;
  String? get email => _email;
  List<String>? get permissions => _permissions;
  dynamic get permissionsRaw => _permissionsRaw;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['id'] = _clientId;
    map['company_name'] = _companyName;
    map['first_name'] = _firstName;
    map['last_name'] = _lastName;
    map['type'] = _type;
    map['address'] = _address;
    map['email'] = _email;
    return map;
  }
}
