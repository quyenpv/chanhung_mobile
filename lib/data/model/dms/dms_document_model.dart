import 'package:chanhung/data/model/global/api_response_payload.dart';

class DmsDocumentsModel {
  bool? success;
  String? message;
  List<DmsDocument>? data;

  DmsDocumentsModel({this.success = true, this.message, this.data});

  DmsDocumentsModel.fromJson(dynamic json) {
    success = apiSuccess(json) ?? true;
    message = apiMessage(json);
    data = apiListPayload(json, 'documents')
        .map((item) => DmsDocument.fromJson(item))
        .toList();
  }
}

class DmsDocumentDetailsModel {
  bool? success;
  String? message;
  DmsDocument? data;

  DmsDocumentDetailsModel({this.success = true, this.message, this.data});

  DmsDocumentDetailsModel.fromJson(dynamic json) {
    success = apiSuccess(json) ?? true;
    message = apiMessage(json);

    final payload = apiPayload(json);
    final document = payload['document'] ??
        (payload['data'] is Map ? payload['data']['document'] : null);
    data = document is Map ? DmsDocument.fromJson(document) : null;
  }
}

class DmsDocument {
  String? id;
  String? docCode;
  String? title;
  String? abstractText;
  String? docGroup;
  String? status;
  String? typeTitle;
  String? organization;
  String? drafterName;
  String? issuedDate;
  String? arrivalDate;
  String? deadline;
  String? securityTitle;
  String? urgencyTitle;
  String? mainFileName;
  int attachmentCount = 0;
  bool canSign = false;
  bool canSignFast = false;
  int totalSigners = 0;
  int signedCount = 0;
  String? nextSignerName;
  String? webUrl;
  String? createdAt;
  List<DmsSigner> signers = [];
  List<DmsDocumentFile> files = [];
  DmsSignPermission? signPermission;

  DmsDocument();

  DmsDocument.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    id = map['id']?.toString();
    docCode = map['doc_code']?.toString();
    title = map['title']?.toString();
    abstractText = map['abstract']?.toString();
    docGroup = map['doc_group']?.toString();
    status = map['status']?.toString();
    typeTitle = map['type_title']?.toString();
    organization = map['org_title']?.toString();
    drafterName = map['drafter_name']?.toString();
    issuedDate = map['issued_date']?.toString();
    arrivalDate = map['arrival_date']?.toString();
    deadline = map['deadline']?.toString();
    securityTitle = map['security_title']?.toString();
    urgencyTitle = map['urgency_title']?.toString();
    mainFileName = map['main_file_name']?.toString();
    attachmentCount = _toInt(map['attachment_count']);
    canSign = _toBool(map['can_sign']);
    canSignFast = _toBool(map['can_sign_fast']);
    totalSigners = _toInt(map['total_signers']);
    signedCount = _toInt(map['signed_count']);
    nextSignerName = map['next_signer_name']?.toString();
    webUrl = map['web_url']?.toString();
    createdAt = map['created_at']?.toString();

    final signerList = map['signers'];
    if (signerList is List) {
      signers = signerList.map((item) => DmsSigner.fromJson(item)).toList();
    }

    final fileList = map['files'];
    if (fileList is List) {
      files = fileList.map((item) => DmsDocumentFile.fromJson(item)).toList();
    }

    final permission = map['sign_permission'];
    if (permission is Map) {
      signPermission = DmsSignPermission.fromJson(permission);
      canSign = signPermission?.canSign ?? canSign;
    }
  }
}

class DmsDocumentFile {
  String? id;
  String? documentId;
  String? fileName;
  String? fileSysName;
  String? fileExt;
  int fileSize = 0;
  bool isSigningFile = false;
  String? fileUrl;
  String? serveUrl;
  String? viewerUrl;
  String? downloadUrl;

  DmsDocumentFile();

  DmsDocumentFile.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    id = map['id']?.toString();
    documentId = map['document_id']?.toString();
    fileName = map['file_name']?.toString();
    fileSysName = map['file_sys_name']?.toString();
    fileExt = map['file_ext']?.toString();
    fileSize = _toInt(map['file_size']);
    isSigningFile = _toBool(map['is_signing_file']);
    fileUrl = map['file_url']?.toString();
    serveUrl = map['serve_url']?.toString();
    viewerUrl = map['viewer_url']?.toString();
    downloadUrl = map['download_url']?.toString();
  }
}

class DmsSigner {
  String? userId;
  String? userName;
  String? signingOrder;
  String? status;
  String? actionType;
  String? roleTitle;
  bool showSignature = false;
  String? signedAt;

  DmsSigner();

  DmsSigner.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    userId = map['user_id']?.toString();
    userName = map['user_name']?.toString();
    signingOrder = map['signing_order']?.toString();
    status = map['status']?.toString();
    actionType = map['action_type']?.toString();
    roleTitle = map['role_title']?.toString();
    showSignature = _toBool(map['show_signature']);
    signedAt = map['signed_at']?.toString();
  }
}

class DmsSignPermission {
  bool canSign = false;
  bool canStartEsign = false;
  bool canStartPfx = false;
  bool hasEsignToken = false;
  bool hasPfxCertificate = false;
  bool hasPfxSavedPassword = false;
  String? message;
  String? webSignUrl;
  String? suggestedPfxProfileSlug;
  DmsSigner? signer;
  DmsEsignCert? esignCert;
  List<DmsPfxProfile> pfxProfiles = [];

  DmsSignPermission();

  DmsSignPermission.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    canSign = _toBool(map['can_sign']);
    canStartEsign = _toBool(map['can_start_esign']);
    canStartPfx = _toBool(map['can_start_pfx']);
    hasEsignToken = _toBool(map['has_esign_token']);
    hasPfxCertificate = _toBool(map['has_pfx_certificate']);
    hasPfxSavedPassword = _toBool(map['has_pfx_saved_password']);
    message = map['message']?.toString();
    webSignUrl = map['web_sign_url']?.toString();
    suggestedPfxProfileSlug = map['suggested_pfx_profile_slug']?.toString();

    if (map['signer'] is Map) {
      signer = DmsSigner.fromJson(map['signer']);
    }
    if (map['esign_cert'] is Map) {
      esignCert = DmsEsignCert.fromJson(map['esign_cert']);
    }
    if (map['pfx_profiles'] is List) {
      pfxProfiles = (map['pfx_profiles'] as List)
          .map((item) => DmsPfxProfile.fromJson(item))
          .toList();
    }
  }

  DmsPfxProfile? get selectedPfxProfile {
    final suggestedSlug = suggestedPfxProfileSlug?.trim();
    if (suggestedSlug?.isNotEmpty == true) {
      for (final profile in pfxProfiles) {
        if (profile.slug == suggestedSlug && profile.hasCertificate) {
          return profile;
        }
      }
    }

    for (final profile in pfxProfiles) {
      if (profile.hasCertificate) {
        return profile;
      }
    }

    return pfxProfiles.isNotEmpty ? pfxProfiles.first : null;
  }
}

class DmsEsignCert {
  String? certName;
  String? serialNumber;
  String? effectiveDate;
  String? expirationDate;

  DmsEsignCert();

  DmsEsignCert.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    certName = (map['certName'] ??
            map['internationalCertName'] ??
            map['name'] ??
            map['subject'])
        ?.toString();
    serialNumber = map['serialNumber']?.toString();
    effectiveDate = map['effectiveDate']?.toString();
    expirationDate = map['expirationDate']?.toString();
  }
}

class DmsPfxProfile {
  String? slug;
  String? label;
  bool hasCertificate = false;
  bool hasSavedPassword = false;

  DmsPfxProfile();

  DmsPfxProfile.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    slug = map['slug']?.toString();
    label = map['label']?.toString();
    hasCertificate = _toBool(map['has_certificate']);
    hasSavedPassword = _toBool(map['has_saved_password']);
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

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().toLowerCase().trim();
  return text == '1' || text == 'true' || text == 'yes';
}
