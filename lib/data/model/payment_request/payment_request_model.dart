class PaymentRequestsResponseModel {
  bool? success;
  String? message;
  PaymentRequestsData? data;

  PaymentRequestsResponseModel({this.success, this.message, this.data});

  PaymentRequestsResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? PaymentRequestsData.fromJson(json['data']) : null;
  }
}

class PaymentRequestsData {
  List<PaymentRequestModel>? paymentRequests;
  Pagination? pagination;

  PaymentRequestsData({this.paymentRequests, this.pagination});

  PaymentRequestsData.fromJson(Map<String, dynamic> json) {
    if (json['payment_requests'] != null) {
      paymentRequests = <PaymentRequestModel>[];
      json['payment_requests'].forEach((v) {
        paymentRequests!.add(PaymentRequestModel.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
}

class Pagination {
  int? total;
  int? count;
  int? perPage;
  int? currentPage;
  int? totalPages;
  int? offset;
  bool? hasMore;

  Pagination({
    this.total,
    this.count,
    this.perPage,
    this.currentPage,
    this.totalPages,
    this.offset,
    this.hasMore,
  });

  Pagination.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    count = json['count'];
    perPage = json['per_page'];
    currentPage = json['current_page'];
    totalPages = json['total_pages'];
    offset = json['offset'];
    hasMore = json['has_more'];
  }
}

class PaymentRequestModel {
  int? id;
  String? requestCode;
  String? requestType;
  String? requestDate;
  String? templateCode;
  String? title;
  int? requesterId;
  String? requesterName;
  int? departmentId;
  String? departmentTitle;
  String? requesterRoleTitle;
  String? fundSource;
  String? budgetCode;
  int? projectId;
  int? contractId;
  String? paymentDeadline;
  double? totalAmount;
  String? amountInWords;
  String? paymentMethod;
  String? beneficiaryPartyType;
  String? beneficiaryName;
  String? beneficiaryBank;
  String? beneficiaryAccount;
  String? status;
  int? companyId;
  String? companyName;
  String? companyCode;

  int? settlementPeriodMonth;
  int? settlementPeriodYear;
  double? settlementPreviousAmount;
  double? settlementAdvanceAmount;
  double? settlementTotalAdvanceAmount;
  double? settlementSpentAmount;
  double? settlementReturnAmount;
  double? settlementExtraPaymentAmount;

  int? prSignedCount;
  int? prSignersTotal;
  String? prWaitingSignerName;
  String? prWaitingSignerRole;
  String? prWaitingSlaStart;
  bool? prSigningOverSla;
  bool? prViewerIsSigner;
  String? createdAt;

  PaymentRequestModel({
    this.id,
    this.requestCode,
    this.requestType,
    this.requestDate,
    this.templateCode,
    this.title,
    this.requesterId,
    this.requesterName,
    this.departmentId,
    this.departmentTitle,
    this.requesterRoleTitle,
    this.fundSource,
    this.budgetCode,
    this.projectId,
    this.contractId,
    this.paymentDeadline,
    this.totalAmount,
    this.amountInWords,
    this.paymentMethod,
    this.beneficiaryPartyType,
    this.beneficiaryName,
    this.beneficiaryBank,
    this.beneficiaryAccount,
    this.status,
    this.companyId,
    this.companyName,
    this.companyCode,
    this.settlementPeriodMonth,
    this.settlementPeriodYear,
    this.settlementPreviousAmount,
    this.settlementAdvanceAmount,
    this.settlementTotalAdvanceAmount,
    this.settlementSpentAmount,
    this.settlementReturnAmount,
    this.settlementExtraPaymentAmount,
    this.prSignedCount,
    this.prSignersTotal,
    this.prWaitingSignerName,
    this.prWaitingSignerRole,
    this.prWaitingSlaStart,
    this.prSigningOverSla,
    this.prViewerIsSigner,
    this.createdAt,
  });

  PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    requestCode = json['request_code']?.toString();
    requestType = json['request_type']?.toString();
    requestDate = json['request_date']?.toString();
    templateCode = json['template_code']?.toString();
    title = json['title']?.toString();
    requesterId = json['requester_id'];
    requesterName = json['requester_name']?.toString();
    departmentId = json['department_id'];
    departmentTitle = json['department_title']?.toString();
    requesterRoleTitle = json['requester_role_title']?.toString();
    fundSource = json['fund_source']?.toString();
    budgetCode = json['budget_code']?.toString();
    projectId = json['project_id'];
    contractId = json['contract_id'];
    paymentDeadline = json['payment_deadline']?.toString();
    totalAmount = json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) : 0.0;
    amountInWords = json['amount_in_words']?.toString();
    paymentMethod = json['payment_method']?.toString();
    beneficiaryPartyType = json['beneficiary_party_type']?.toString();
    beneficiaryName = json['beneficiary_name']?.toString();
    beneficiaryBank = json['beneficiary_bank']?.toString();
    beneficiaryAccount = json['beneficiary_account']?.toString();
    status = json['status']?.toString();
    companyId = json['company_id'];
    companyName = json['company_name']?.toString();
    companyCode = json['company_code']?.toString();
    settlementPeriodMonth = json['settlement_period_month'];
    settlementPeriodYear = json['settlement_period_year'];
    settlementPreviousAmount = json['settlement_previous_amount'] != null ? double.tryParse(json['settlement_previous_amount'].toString()) : 0.0;
    settlementAdvanceAmount = json['settlement_advance_amount'] != null ? double.tryParse(json['settlement_advance_amount'].toString()) : 0.0;
    settlementTotalAdvanceAmount = json['settlement_total_advance_amount'] != null ? double.tryParse(json['settlement_total_advance_amount'].toString()) : 0.0;
    settlementSpentAmount = json['settlement_spent_amount'] != null ? double.tryParse(json['settlement_spent_amount'].toString()) : 0.0;
    settlementReturnAmount = json['settlement_return_amount'] != null ? double.tryParse(json['settlement_return_amount'].toString()) : 0.0;
    settlementExtraPaymentAmount = json['settlement_extra_payment_amount'] != null ? double.tryParse(json['settlement_extra_payment_amount'].toString()) : 0.0;
    prSignedCount = json['pr_signed_count'];
    prSignersTotal = json['pr_signers_total'];
    prWaitingSignerName = json['pr_waiting_signer_name']?.toString();
    prWaitingSignerRole = json['pr_waiting_signer_role']?.toString();
    prWaitingSlaStart = json['pr_waiting_sla_start']?.toString();
    prSigningOverSla = json['pr_signing_over_sla'] == true;
    prViewerIsSigner = json['pr_viewer_is_signer'] == true;
    createdAt = json['created_at']?.toString();
  }
}

class PaymentRequestDetailResponseModel {
  bool? success;
  String? message;
  PaymentRequestDetailData? data;

  PaymentRequestDetailResponseModel({this.success, this.message, this.data});

  PaymentRequestDetailResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? PaymentRequestDetailData.fromJson(json['data']) : null;
  }
}

class PaymentRequestDetailData {
  PaymentRequestDetailModel? paymentRequest;

  PaymentRequestDetailData({this.paymentRequest});

  PaymentRequestDetailData.fromJson(Map<String, dynamic> json) {
    paymentRequest = json['payment_request'] != null ? PaymentRequestDetailModel.fromJson(json['payment_request']) : null;
  }
}

class PaymentRequestDetailModel {
  int? id;
  String? requestCode;
  String? requestType;
  String? requestDate;
  String? templateCode;
  String? title;
  int? requesterId;
  String? requesterName;
  int? departmentId;
  String? departmentTitle;
  String? requesterRoleTitle;
  String? fundSource;
  String? budgetCode;
  int? projectId;
  int? contractId;
  String? paymentDeadline;
  double? totalAmount;
  String? amountInWords;
  String? paymentMethod;
  String? beneficiaryPartyType;
  String? beneficiaryName;
  String? beneficiaryBank;
  String? beneficiaryAccount;
  String? status;
  int? companyId;
  String? companyName;
  String? companyCode;

  int? settlementPeriodMonth;
  int? settlementPeriodYear;
  double? settlementPreviousAmount;
  double? settlementAdvanceAmount;
  double? settlementTotalAdvanceAmount;
  double? settlementSpentAmount;
  double? settlementReturnAmount;
  double? settlementExtraPaymentAmount;

  int? prSignedCount;
  int? prSignersTotal;
  String? prWaitingSignerName;
  String? prWaitingSignerRole;
  String? prWaitingSlaStart;
  bool? prSigningOverSla;
  bool? prViewerIsSigner;
  String? createdAt;

  List<PaymentRequestFile>? files;
  List<PaymentRequestLine>? lines;
  List<PaymentRequestAttachment>? attachments;
  List<PaymentRequestSigner>? signers;
  List<SettlementSource>? settlementSources;
  List<SettlementExpense>? settlementExpenses;

  bool? canSign;
  String? signerRole;

  PaymentRequestDetailModel({
    this.id,
    this.requestCode,
    this.requestType,
    this.requestDate,
    this.templateCode,
    this.title,
    this.requesterId,
    this.requesterName,
    this.departmentId,
    this.departmentTitle,
    this.requesterRoleTitle,
    this.fundSource,
    this.budgetCode,
    this.projectId,
    this.contractId,
    this.paymentDeadline,
    this.totalAmount,
    this.amountInWords,
    this.paymentMethod,
    this.beneficiaryPartyType,
    this.beneficiaryName,
    this.beneficiaryBank,
    this.beneficiaryAccount,
    this.status,
    this.companyId,
    this.companyName,
    this.companyCode,
    this.settlementPeriodMonth,
    this.settlementPeriodYear,
    this.settlementPreviousAmount,
    this.settlementAdvanceAmount,
    this.settlementTotalAdvanceAmount,
    this.settlementSpentAmount,
    this.settlementReturnAmount,
    this.settlementExtraPaymentAmount,
    this.prSignedCount,
    this.prSignersTotal,
    this.prWaitingSignerName,
    this.prWaitingSignerRole,
    this.prWaitingSlaStart,
    this.prSigningOverSla,
    this.prViewerIsSigner,
    this.createdAt,
    this.files,
    this.lines,
    this.attachments,
    this.signers,
    this.settlementSources,
    this.settlementExpenses,
    this.canSign,
    this.signerRole,
  });

  PaymentRequestDetailModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    requestCode = json['request_code']?.toString();
    requestType = json['request_type']?.toString();
    requestDate = json['request_date']?.toString();
    templateCode = json['template_code']?.toString();
    title = json['title']?.toString();
    requesterId = json['requester_id'];
    requesterName = json['requester_name']?.toString();
    departmentId = json['department_id'];
    departmentTitle = json['department_title']?.toString();
    requesterRoleTitle = json['requester_role_title']?.toString();
    fundSource = json['fund_source']?.toString();
    budgetCode = json['budget_code']?.toString();
    projectId = json['project_id'];
    contractId = json['contract_id'];
    paymentDeadline = json['payment_deadline']?.toString();
    totalAmount = json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) : 0.0;
    amountInWords = json['amount_in_words']?.toString();
    paymentMethod = json['payment_method']?.toString();
    beneficiaryPartyType = json['beneficiary_party_type']?.toString();
    beneficiaryName = json['beneficiary_name']?.toString();
    beneficiaryBank = json['beneficiary_bank']?.toString();
    beneficiaryAccount = json['beneficiary_account']?.toString();
    status = json['status']?.toString();
    companyId = json['company_id'];
    companyName = json['company_name']?.toString();
    companyCode = json['company_code']?.toString();
    settlementPeriodMonth = json['settlement_period_month'];
    settlementPeriodYear = json['settlement_period_year'];
    settlementPreviousAmount = json['settlement_previous_amount'] != null ? double.tryParse(json['settlement_previous_amount'].toString()) : 0.0;
    settlementAdvanceAmount = json['settlement_advance_amount'] != null ? double.tryParse(json['settlement_advance_amount'].toString()) : 0.0;
    settlementTotalAdvanceAmount = json['settlement_total_advance_amount'] != null ? double.tryParse(json['settlement_total_advance_amount'].toString()) : 0.0;
    settlementSpentAmount = json['settlement_spent_amount'] != null ? double.tryParse(json['settlement_spent_amount'].toString()) : 0.0;
    settlementReturnAmount = json['settlement_return_amount'] != null ? double.tryParse(json['settlement_return_amount'].toString()) : 0.0;
    settlementExtraPaymentAmount = json['settlement_extra_payment_amount'] != null ? double.tryParse(json['settlement_extra_payment_amount'].toString()) : 0.0;
    prSignedCount = json['pr_signed_count'];
    prSignersTotal = json['pr_signers_total'];
    prWaitingSignerName = json['pr_waiting_signer_name']?.toString();
    prWaitingSignerRole = json['pr_waiting_signer_role']?.toString();
    prWaitingSlaStart = json['pr_waiting_sla_start']?.toString();
    prSigningOverSla = json['pr_signing_over_sla'] == true;
    prViewerIsSigner = json['pr_viewer_is_signer'] == true;
    createdAt = json['created_at']?.toString();

    if (json['files'] != null) {
      files = <PaymentRequestFile>[];
      json['files'].forEach((v) {
        files!.add(PaymentRequestFile.fromJson(v));
      });
    }
    if (json['lines'] != null) {
      lines = <PaymentRequestLine>[];
      json['lines'].forEach((v) {
        lines!.add(PaymentRequestLine.fromJson(v));
      });
    }
    if (json['attachments'] != null) {
      attachments = <PaymentRequestAttachment>[];
      json['attachments'].forEach((v) {
        attachments!.add(PaymentRequestAttachment.fromJson(v));
      });
    }
    if (json['signers'] != null) {
      signers = <PaymentRequestSigner>[];
      json['signers'].forEach((v) {
        signers!.add(PaymentRequestSigner.fromJson(v));
      });
    }
    if (json['settlement_sources'] != null) {
      settlementSources = <SettlementSource>[];
      json['settlement_sources'].forEach((v) {
        settlementSources!.add(SettlementSource.fromJson(v));
      });
    }
    if (json['settlement_expenses'] != null) {
      settlementExpenses = <SettlementExpense>[];
      json['settlement_expenses'].forEach((v) {
        settlementExpenses!.add(SettlementExpense.fromJson(v));
      });
    }

    canSign = json['can_sign'] == true;
    signerRole = json['signer_role']?.toString();
  }
}

class PaymentRequestFile {
  int? id;
  int? paymentRequestId;
  String? fileName;
  String? fileSysName;
  String? fileExt;
  int? fileSize;
  bool? isSigningFile;
  String? serveUrl;
  String? viewerUrl;
  String? downloadUrl;

  PaymentRequestFile({
    this.id,
    this.paymentRequestId,
    this.fileName,
    this.fileSysName,
    this.fileExt,
    this.fileSize,
    this.isSigningFile,
    this.serveUrl,
    this.viewerUrl,
    this.downloadUrl,
  });

  PaymentRequestFile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    paymentRequestId = json['payment_request_id'];
    fileName = json['file_name']?.toString();
    fileSysName = json['file_sys_name']?.toString();
    fileExt = json['file_ext']?.toString();
    fileSize = json['file_size'];
    isSigningFile = json['is_signing_file'] == true;
    serveUrl = json['serve_url']?.toString();
    viewerUrl = json['viewer_url']?.toString();
    downloadUrl = json['download_url']?.toString();
  }
}

class PaymentRequestLine {
  int? id;
  int? lineNo;
  String? title;
  double? quantity;
  String? unitType;
  double? rate;
  double? amount;
  int? taxId;
  double? taxPercentage;
  double? taxAmount;
  double? totalAmount;
  String? note;

  PaymentRequestLine({
    this.id,
    this.lineNo,
    this.title,
    this.quantity,
    this.unitType,
    this.rate,
    this.amount,
    this.taxId,
    this.taxPercentage,
    this.taxAmount,
    this.totalAmount,
    this.note,
  });

  PaymentRequestLine.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    lineNo = json['line_no'];
    title = json['title']?.toString();
    quantity = json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : 0.0;
    unitType = json['unit_type']?.toString();
    rate = json['rate'] != null ? double.tryParse(json['rate'].toString()) : 0.0;
    amount = json['amount'] != null ? double.tryParse(json['amount'].toString()) : 0.0;
    taxId = json['tax_id'];
    taxPercentage = json['tax_percentage'] != null ? double.tryParse(json['tax_percentage'].toString()) : 0.0;
    taxAmount = json['tax_amount'] != null ? double.tryParse(json['tax_amount'].toString()) : 0.0;
    totalAmount = json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) : 0.0;
    note = json['note']?.toString();
  }
}

class PaymentRequestAttachment {
  int? id;
  String? fileName;
  int? fileSize;
  String? filePath;
  String? description;
  String? createdAt;

  PaymentRequestAttachment({
    this.id,
    this.fileName,
    this.fileSize,
    this.filePath,
    this.description,
    this.createdAt,
  });

  PaymentRequestAttachment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fileName = json['file_name']?.toString();
    fileSize = json['file_size'];
    filePath = json['file_path']?.toString();
    description = json['description']?.toString();
    createdAt = json['created_at']?.toString();
  }
}

class PaymentRequestSigner {
  int? id;
  int? userId;
  String? userName;
  String? userEmail;
  int? signingOrder;
  String? roleTitle;
  String? actionType;
  String? status;
  String? signedAt;
  String? note;
  String? signatureMethod;

  PaymentRequestSigner({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.signingOrder,
    this.roleTitle,
    this.actionType,
    this.status,
    this.signedAt,
    this.note,
    this.signatureMethod,
  });

  PaymentRequestSigner.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    userName = json['user_name']?.toString();
    userEmail = json['user_email']?.toString();
    signingOrder = json['signing_order'];
    roleTitle = json['role_title']?.toString();
    actionType = json['action_type']?.toString();
    status = json['status']?.toString();
    signedAt = json['signed_at']?.toString();
    note = json['note']?.toString();
    signatureMethod = json['signature_method']?.toString();
  }
}

class SettlementSource {
  int? id;
  int? sourcePaymentRequestId;
  int? lineNo;
  String? sourceCode;
  String? sourceDate;
  String? sourceTitle;
  double? amount;
  String? paymentProofFile;
  String? paymentProofNote;

  SettlementSource({
    this.id,
    this.sourcePaymentRequestId,
    this.lineNo,
    this.sourceCode,
    this.sourceDate,
    this.sourceTitle,
    this.amount,
    this.paymentProofFile,
    this.paymentProofNote,
  });

  SettlementSource.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sourcePaymentRequestId = json['source_payment_request_id'];
    lineNo = json['line_no'];
    sourceCode = json['source_code']?.toString();
    sourceDate = json['source_date']?.toString();
    sourceTitle = json['source_title']?.toString();
    amount = json['amount'] != null ? double.tryParse(json['amount'].toString()) : 0.0;
    paymentProofFile = json['payment_proof_file']?.toString();
    paymentProofNote = json['payment_proof_note']?.toString();
  }
}

class SettlementExpense {
  int? id;
  int? lineNo;
  String? voucherNo;
  String? voucherDate;
  String? description;
  double? amount;
  String? note;

  SettlementExpense({
    this.id,
    this.lineNo,
    this.voucherNo,
    this.voucherDate,
    this.description,
    this.amount,
    this.note,
  });

  SettlementExpense.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    lineNo = json['line_no'];
    voucherNo = json['voucher_no']?.toString();
    voucherDate = json['voucher_date']?.toString();
    description = json['description']?.toString();
    amount = json['amount'] != null ? double.tryParse(json['amount'].toString()) : 0.0;
    note = json['note']?.toString();
  }
}
