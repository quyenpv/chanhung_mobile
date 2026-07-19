import 'package:chanhung/data/model/global/api_response_payload.dart';

class RegistrationResponseModel {
  RegistrationResponseModel({
    bool? success,
    String? message,
  }) {
    _success = success;
    _message = message;
  }

  RegistrationResponseModel.fromJson(dynamic json) {
    _success = apiSuccess(json);
    _message = apiMessage(json) ?? '';
  }
  bool? _success;
  String? _message;

  bool? get success => _success;
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    map['message'] = _message;
    return map;
  }
}
