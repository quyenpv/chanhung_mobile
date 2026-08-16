import 'package:chanhung/data/model/project/project_dashboard_model.dart';

class ProjectDetailsModel {
  ProjectDetailsModel({
    bool? success,
    String? message,
    Project? data,
  }) {
    _success = success;
    _message = message;
    _data = data;
  }

  ProjectDetailsModel.fromJson(dynamic json) {
    _success = json['success'] == true || json['success'] == 1;
    _message = json['message']?.toString();
    dynamic raw = json['data'];
    if (raw is Map && raw['project'] is Map && raw['title'] == null) {
      raw = raw['project'];
    }
    _data = raw is Map ? Project.fromJson(raw) : null;
  }
  bool? _success;
  String? _message;
  Project? _data;

  bool? get success => _success;
  String? get message => _message;
  Project? get data => _data;

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
    List<Comment>? comments,
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
    _comments = comments;
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
    _statusIcon = json['status_icon']?.toString();
    _labelsList = json['labels_list']?.toString();
    _projectCode = json['project_code']?.toString();
    _address = json['address']?.toString();
    _projectTypeTitle = json['project_type_title']?.toString();
    _totalSettledAmount = json['total_settled_amount']?.toString();
    _totalNetPayable = json['total_net_payable']?.toString();
    _remaining = json['remaining']?.toString();
    _paymentProgress = json['payment_progress']?.toString();
    _progress = json['progress']?.toString();
    _health = json['health']?.toString();
    _budget = json['acc_budget_amount']?.toString();
    _actualCost = json['acc_actual_cost']?.toString();
    _memberCount = json['member_count']?.toString();
    _counts = json['counts'] is Map
        ? ProjectCounts.fromJson(json['counts'])
        : ProjectCounts();
    _taskStats = json['task_stats'] is Map
        ? ProjectTaskStats.fromJson(json['task_stats'])
        : ProjectTaskStats();
    _finance = json['finance'] is Map
        ? PartyFinance.fromJson(json['finance'])
        : PartyFinance();
    if (json['comments'] != null) {
      _comments = [];
      json['comments'].forEach((v) {
        _comments?.add(Comment.fromJson(v));
      });
    }
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
  List<Comment>? _comments;
  String? _projectCode;
  String? _address;
  String? _projectTypeTitle;
  String? _totalSettledAmount;
  String? _totalNetPayable;
  String? _remaining;
  String? _paymentProgress;
  String? _progress;
  String? _health;
  String? _budget;
  String? _actualCost;
  String? _memberCount;
  ProjectCounts? _counts;
  ProjectTaskStats? _taskStats;
  PartyFinance? _finance;

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
  List<Comment>? get comments => _comments;
  String? get projectCode => _projectCode;
  String? get address => _address;
  String? get projectTypeTitle => _projectTypeTitle;
  String? get totalSettledAmount => _totalSettledAmount;
  String? get totalNetPayable => _totalNetPayable;
  String? get remaining => _remaining;
  String? get paymentProgress => _paymentProgress;
  String? get progress => _progress;
  String? get health => _health;
  String? get budget => _budget;
  String? get actualCost => _actualCost;
  String? get memberCount => _memberCount;
  ProjectCounts get counts => _counts ?? ProjectCounts();
  ProjectTaskStats get taskStats => _taskStats ?? ProjectTaskStats();
  PartyFinance get finance => _finance ?? PartyFinance();

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
    if (_comments != null) {
      map['comments'] = _comments?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Comment {
  Comment({
    String? id,
    String? createdBy,
    String? createdAt,
    String? description,
    List<CommentFile>? files,
    String? projectId,
    String? commentId,
    String? taskId,
    String? fileId,
    String? customerFeedbackId,
    String? parentCommmentId,
    String? createdByUser,
    String? createdByAvatar,
    String? userType,
    String? totalReplies,
    String? commentLikers,
    String? totalLikes,
  }) {
    _id = id;
    _createdBy = createdBy;
    _createdAt = createdAt;
    _description = description;
    _files = files;
    _projectId = projectId;
    _commentId = commentId;
    _taskId = taskId;
    _fileId = fileId;
    _customerFeedbackId = customerFeedbackId;
    _parentCommmentId = parentCommmentId;
    _createdByUser = createdByUser;
    _createdByAvatar = createdByAvatar;
    _userType = userType;
    _totalReplies = totalReplies;
    _commentLikers = commentLikers;
    _totalLikes = totalLikes;
  }

  Comment.fromJson(dynamic json) {
    _id = json['id']?.toString();
    _createdBy = json['created_by']?.toString();
    _createdAt = json['created_at']?.toString();
    _description = json['description']?.toString();
    if (json['files'] != null) {
      _files = [];
      json['files'].forEach((v) {
        _files?.add(CommentFile.fromJson(v));
      });
    }
    _projectId = json['project_id'];
    _commentId = json['comment_id'];
    _taskId = json['task_id'];
    _fileId = json['file_id'];
    _customerFeedbackId = json['customer_feedback_id'];
    _parentCommmentId = json['parent_commment_id'];
    _createdByUser = json['created_by_user'];
    _createdByAvatar = json['created_by_avatar'];
    _userType = json['user_type'];
    _totalReplies = json['total_replies'];
    _commentLikers = json['comment_likers'];
    _totalLikes = json['total_likes'];
  }

  String? _id;
  String? _createdBy;
  String? _createdAt;
  String? _description;
  List<CommentFile>? _files;
  String? _projectId;
  String? _commentId;
  String? _taskId;
  String? _fileId;
  String? _customerFeedbackId;
  String? _parentCommmentId;
  String? _createdByUser;
  String? _createdByAvatar;
  String? _userType;
  String? _totalReplies;
  String? _commentLikers;
  String? _totalLikes;

  String? get id => _id;
  String? get createdBy => _createdBy;
  String? get createdAt => _createdAt;
  String? get description => _description;
  List<CommentFile>? get files => _files;
  String? get projectId => _projectId;
  String? get commentId => _commentId;
  String? get taskId => _taskId;
  String? get fileId => _fileId;
  String? get customerFeedbackId => _customerFeedbackId;
  String? get parentCommmentId => _parentCommmentId;
  String? get createdByUser => _createdByUser;
  String? get createdByAvatar => _createdByAvatar;
  String? get userType => _userType;
  String? get totalReplies => _totalReplies;
  String? get commentLikers => _commentLikers;
  String? get totalLikes => _totalLikes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['created_by'] = _createdBy;
    map['created_at'] = _createdAt;
    map['description'] = _description;
    map['files'] = _files;
    if (_files != null) {
      map['files'] = _files?.map((v) => v.toJson()).toList();
    }
    map['project_id'] = _projectId;
    map['comment_id'] = _commentId;
    map['task_id'] = _taskId;
    map['file_id'] = _fileId;
    map['customer_feedback_id'] = _customerFeedbackId;
    map['parent_commment_id'] = _parentCommmentId;
    map['created_by_user'] = _createdByUser;
    map['created_by_avatar'] = _createdByAvatar;
    map['user_type'] = _userType;
    map['total_replies'] = _totalReplies;
    map['comment_likers'] = _commentLikers;
    map['total_likes'] = _totalLikes;
    return map;
  }
}

class CommentFile {
  CommentFile({
    String? fileName,
    String? fileSize,
    String? fileId,
    String? serviceType,
  }) {
    _fileName = fileName;
    _fileSize = fileSize;
    _fileId = fileId;
    _serviceType = serviceType;
  }

  CommentFile.fromJson(dynamic json) {
    _fileName = json['file_name'];
    _fileSize = json['file_size'];
    _fileId = json['file_id'];
    _serviceType = json['service_type'];
  }

  String? _fileName;
  String? _fileSize;
  String? _fileId;
  String? _serviceType;

  String? get fileName => _fileName;
  String? get fileSize => _fileSize;
  String? get fileId => _fileId;
  String? get serviceType => _serviceType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['file_name'] = _fileName;
    map['file_size'] = _fileSize;
    map['file_id'] = _fileId;
    map['service_type'] = _serviceType;
    return map;
  }
}
