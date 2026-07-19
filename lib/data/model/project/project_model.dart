import 'package:chanhung/data/model/global/api_response_payload.dart';

class ProjectsModel {
  ProjectsModel({
    bool? success,
    String? message,
    List<Project>? data,
  }) {
    _success = success;
    _message = message;
    _data = data;
  }

  ProjectsModel.fromJson(dynamic json) {
    _success = apiSuccess(json);
    _message = apiMessage(json) ?? '';
    _data = apiListPayload(json, 'projects')
        .map((v) => Project.fromJson(v))
        .toList();
  }
  bool? _success;
  String? _message;
  List<Project>? _data;

  bool? get success => _success;
  String? get message => _message;
  List<Project>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = _success;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Project {
  Project({
    String? id,
    String? title,
    String? description,
    String? projectType,
    String? startDate,
    String? deadline,
    String? clientId,
    String? createdDate,
    String? createdBy,
    String? status,
    String? statusId,
    String? labels,
    String? price,
    String? starredBy,
    String? estimateId,
    String? orderId,
    String? proposalId,
    String? deleted,
    String? companyName,
    String? currencySymbol,
    String? totalPoints,
    String? completedPoints,
    String? statusKeyName,
    String? titleLanguageKey,
    String? statusTitle,
    String? statusIcon,
    String? labelsList,
  }) {
    _id = id;
    _title = title;
    _description = description;
    _projectType = projectType;
    _startDate = startDate;
    _deadline = deadline;
    _clientId = clientId;
    _createdDate = createdDate;
    _createdBy = createdBy;
    _status = status;
    _statusId = statusId;
    _labels = labels;
    _price = price;
    _starredBy = starredBy;
    _estimateId = estimateId;
    _orderId = orderId;
    _proposalId = proposalId;
    _deleted = deleted;
    _companyName = companyName;
    _currencySymbol = currencySymbol;
    _totalPoints = totalPoints;
    _completedPoints = completedPoints;
    _statusKeyName = statusKeyName;
    _titleLanguageKey = titleLanguageKey;
    _statusTitle = statusTitle;
    _statusIcon = statusIcon;
    _labelsList = labelsList;
  }
  Project.fromJson(dynamic json) {
    if (json is! Map) {
      return;
    }
    _id = json['id']?.toString();
    _title = json['title']?.toString();
    _description = json['description']?.toString();
    _projectType = json['project_type']?.toString();
    _startDate = json['start_date']?.toString();
    _deadline = json['deadline']?.toString();
    _clientId = json['client_id']?.toString();
    _createdDate = json['created_date']?.toString();
    _createdBy = json['created_by']?.toString();
    _status = json['status']?.toString();
    _statusId = json['status_id']?.toString();
    _labels = json['labels']?.toString();
    _price = json['price']?.toString();
    _starredBy = json['starred_by']?.toString();
    _estimateId = json['estimate_id']?.toString();
    _orderId = json['order_id']?.toString();
    _proposalId = json['proposal_id']?.toString();
    _deleted = json['deleted']?.toString();
    _companyName = json['company_name']?.toString();
    _currencySymbol = json['currency_symbol']?.toString();
    _totalPoints = json['total_points']?.toString();
    _completedPoints = json['completed_points']?.toString();
    _statusKeyName = json['status_key_name']?.toString();
    _titleLanguageKey = json['title_language_key']?.toString();
    _statusTitle = json['status_title']?.toString();
    _statusIcon = (json['status_icon'] ?? json['status_color'])?.toString();
    _labelsList = json['labels_list']?.toString();
  }

  String? _id;
  String? _title;
  String? _description;
  String? _projectType;
  String? _startDate;
  String? _deadline;
  String? _clientId;
  String? _createdDate;
  String? _createdBy;
  String? _status;
  String? _statusId;
  String? _labels;
  String? _price;
  String? _starredBy;
  String? _estimateId;
  String? _orderId;
  String? _proposalId;
  String? _deleted;
  String? _companyName;
  String? _currencySymbol;
  String? _totalPoints;
  String? _completedPoints;
  String? _statusKeyName;
  String? _titleLanguageKey;
  String? _statusTitle;
  String? _statusIcon;
  String? _labelsList;

  String? get id => _id;
  String? get title => _title;
  String? get description => _description;
  String? get projectType => _projectType;
  String? get startDate => _startDate;
  String? get deadline => _deadline;
  String? get clientId => _clientId;
  String? get createdDate => _createdDate;
  String? get createdBy => _createdBy;
  String? get status => _status;
  String? get statusId => _statusId;
  String? get labels => _labels;
  String? get price => _price;
  String? get starredBy => _starredBy;
  String? get estimateId => _estimateId;
  String? get orderId => _orderId;
  String? get proposalId => _proposalId;
  String? get deleted => _deleted;
  String? get companyName => _companyName;
  String? get currencySymbol => _currencySymbol;
  String? get totalPoints => _totalPoints;
  String? get completedPoints => _completedPoints;
  String? get statusKeyName => _statusKeyName;
  String? get titleLanguageKey => _titleLanguageKey;
  String? get statusTitle => _statusTitle;
  String? get statusIcon => _statusIcon;
  String? get labelsList => _labelsList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['description'] = _description;
    map['project_type'] = _projectType;
    map['start_date'] = _startDate;
    map['deadline'] = _deadline;
    map['client_id'] = _clientId;
    map['created_date'] = _createdDate;
    map['created_by'] = _createdBy;
    map['status'] = _status;
    map['status_id'] = _statusId;
    map['labels'] = _labels;
    map['price'] = _price;
    map['starred_by'] = _starredBy;
    map['estimate_id'] = _estimateId;
    map['order_id'] = _orderId;
    map['proposal_id'] = _proposalId;
    map['deleted'] = _deleted;
    map['company_name'] = _companyName;
    map['currency_symbol'] = _currencySymbol;
    map['total_points'] = _totalPoints;
    map['completed_points'] = _completedPoints;
    map['status_key_name'] = _statusKeyName;
    map['title_language_key'] = _titleLanguageKey;
    map['status_title'] = _statusTitle;
    map['status_icon'] = _statusIcon;
    map['labels_list'] = _labelsList;
    return map;
  }
}
