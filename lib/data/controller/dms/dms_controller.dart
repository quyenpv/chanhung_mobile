import 'dart:convert';

import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/dms/dms_document_model.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/repo/dms/dms_repo.dart';
import 'package:chanhung/view/components/dialog/app_alert_dialog.dart';
import 'package:chanhung/view/components/dialog/pfx_password_dialog.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class DmsController extends GetxController {
  DmsRepo dmsRepo;
  DmsController({required this.dmsRepo});

  bool isLoading = true;
  bool isDetailsLoading = true;
  DmsDocumentsModel documentsModel = DmsDocumentsModel(data: []);
  DmsDocumentDetailsModel documentDetailsModel = DmsDocumentDetailsModel();
  int selectedFilterIndex = 0;
  String searchText = '';
  bool isSigning = false;
  String signingStatusText = '';

  final List<DmsDocumentFilter> filters = const [
    DmsDocumentFilter(label: LocalStrings.all),
    DmsDocumentFilter(
        label: LocalStrings.incomingDocuments, docGroup: 'incoming'),
    DmsDocumentFilter(
        label: LocalStrings.outgoingDocuments, docGroup: 'outgoing'),
    DmsDocumentFilter(
        label: LocalStrings.waitingForSignature, filter: 'signing_waiting'),
  ];

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();
    await loadDocuments(showLoader: false);
    isLoading = false;
    update();
  }

  Future<void> loadDocuments({bool showLoader = true}) async {
    if (showLoader) {
      isLoading = true;
      update();
    }

    final selectedFilter = filters[selectedFilterIndex];
    ResponseModel responseModel = await dmsRepo.getDocuments(
      docGroup: selectedFilter.docGroup,
      filter: selectedFilter.filter,
      search: searchText,
    );

    try {
      if (responseModel.statusCode == 200) {
        documentsModel =
            DmsDocumentsModel.fromJson(jsonDecode(responseModel.responseJson));
      } else {
        documentsModel = DmsDocumentsModel(data: []);
        CustomSnackBar.error(errorList: [
          responseModel.message.isNotEmpty
              ? responseModel.message
              : LocalStrings.somethingWentWrong.tr
        ]);
      }
    } catch (_) {
      documentsModel = DmsDocumentsModel(data: []);
      CustomSnackBar.error(errorList: [
        responseModel.message.isNotEmpty
            ? responseModel.message
            : LocalStrings.badResponseMsg.tr
      ]);
    }

    isLoading = false;
    update();
  }

  Future<void> setFilter(int index) async {
    selectedFilterIndex = index;
    await loadDocuments();
  }

  Future<void> searchDocuments(String value) async {
    searchText = value.trim();
    await loadDocuments();
  }

  Future<void> clearSearch() async {
    if (searchText.isEmpty) {
      return;
    }
    searchText = '';
    await loadDocuments();
  }

  Future<void> loadDocumentDetails(dynamic documentId) async {
    isDetailsLoading = true;
    documentDetailsModel = DmsDocumentDetailsModel();
    update();

    ResponseModel responseModel = await dmsRepo.getDocumentDetails(documentId);
    try {
      if (responseModel.statusCode == 200) {
        documentDetailsModel = DmsDocumentDetailsModel.fromJson(
            jsonDecode(responseModel.responseJson));
        if (documentDetailsModel.data != null) {
          await refreshSignPermission(documentId, notify: false);
        }
      } else {
        CustomSnackBar.error(errorList: [
          responseModel.message.isNotEmpty
              ? responseModel.message
              : LocalStrings.somethingWentWrong.tr
        ]);
      }
    } catch (_) {
      CustomSnackBar.error(errorList: [
        responseModel.message.isNotEmpty
            ? responseModel.message
            : LocalStrings.badResponseMsg.tr
      ]);
    }

    isDetailsLoading = false;
    update();
  }

  Future<void> refreshSignPermission(dynamic documentId,
      {bool notify = true}) async {
    ResponseModel responseModel = await dmsRepo.getSignPermission(documentId);
    try {
      if (responseModel.statusCode == 200) {
        final payload = apiPayload(jsonDecode(responseModel.responseJson));
        final permission = payload['permission'] ??
            (payload['data'] is Map ? payload['data']['permission'] : null);
        final document = documentDetailsModel.data;
        if (permission is Map && document != null) {
          document.signPermission = DmsSignPermission.fromJson(permission);
          document.canSign = document.signPermission?.canSign ?? false;
          if (notify) {
            update();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> startEsignSigning(dynamic documentId) async {
    if (isSigning) {
      return;
    }

    isSigning = true;
    signingStatusText = 'Đang gửi yêu cầu ký số...';
    update();

    ResponseModel responseModel = await dmsRepo.startEsign(documentId);
    try {
      if (responseModel.statusCode != 200) {
        isSigning = false;
        signingStatusText = '';
        update();
        await AppAlert.error(
          responseModel.message.isNotEmpty
              ? responseModel.message
              : LocalStrings.somethingWentWrong.tr,
          title: LocalStrings.signFailedTitle.tr,
        );
        return;
      }

      final startPayload = apiPayload(jsonDecode(responseModel.responseJson));
      final startData = startPayload['data'] is Map
          ? Map<String, dynamic>.from(startPayload['data'])
          : startPayload;
      final transactionId = startData['transaction_id']?.toString() ?? '';
      if (transactionId.isEmpty) {
        isSigning = false;
        signingStatusText = '';
        update();
        await AppAlert.error(
          startData['message']?.toString() ?? LocalStrings.badResponseMsg.tr,
          title: LocalStrings.signFailedTitle.tr,
        );
        return;
      }

      signingStatusText = 'Chờ xác nhận trên MISA eSign App...';
      update();

      for (int i = 0; i < 24; i++) {
        await Future.delayed(const Duration(seconds: 5));
        ResponseModel statusResponse =
            await dmsRepo.getEsignStatus(transactionId);
        if (statusResponse.statusCode != 200) {
          continue;
        }

        final statusPayload =
            apiPayload(jsonDecode(statusResponse.responseJson));
        final statusData = statusPayload['data'] is Map
            ? Map<String, dynamic>.from(statusPayload['data'])
            : statusPayload;
        final status = statusData['status']?.toString() ?? 'PENDING';

        if (status == 'SUCCESS') {
          signingStatusText = '';
          isSigning = false;
          await loadDocumentDetails(documentId);
          await AppAlert.success(
            'Ký eSign thành công',
            title: LocalStrings.signSuccessTitle.tr,
          );
          return;
        }

        if (status == 'FAILED' || status == 'REJECTED' || status == 'EXPIRED') {
          isSigning = false;
          signingStatusText = '';
          update();
          await AppAlert.error(
            statusData['message']?.toString().isNotEmpty == true
                ? statusData['message'].toString()
                : 'Yêu cầu ký eSign không thành công',
            title: LocalStrings.signFailedTitle.tr,
          );
          return;
        }
      }

      isSigning = false;
      signingStatusText = '';
      update();
      await AppAlert.error(
        'Chưa nhận được xác nhận eSign. Vui lòng kiểm tra lại sau.',
        title: LocalStrings.signFailedTitle.tr,
      );
    } catch (_) {
      isSigning = false;
      signingStatusText = '';
      update();
      await AppAlert.error(
        LocalStrings.badResponseMsg.tr,
        title: LocalStrings.signFailedTitle.tr,
      );
    }
  }

  Future<void> startPfxSigning(
    dynamic documentId, {
    String pfxPassword = '',
  }) async {
    if (isSigning) {
      return;
    }

    final permission = documentDetailsModel.data?.signPermission;
    final selectedProfile = permission?.selectedPfxProfile;
    if (selectedProfile?.hasCertificate != true) {
      await AppAlert.error(
        LocalStrings.pfxNotConfigured.tr,
        title: LocalStrings.signFailedTitle.tr,
      );
      return;
    }

    // Bắt buộc hiện modal nhập mật khẩu trước khi gọi API (mọi máy).
    // Không dựa vào cờ has_saved_password — tránh ký rỗng khi file .pwd hỏng.
    var trimmedPassword = pfxPassword.trim();
    if (trimmedPassword.isEmpty) {
      final typed = await PfxPasswordDialog.show();
      if (typed == null) {
        return; // Người dùng hủy
      }
      trimmedPassword = typed.trim();
    }
    if (trimmedPassword.isEmpty) {
      await AppAlert.error(
        LocalStrings.enterPfxPassword.tr,
        title: LocalStrings.signFailedTitle.tr,
      );
      return;
    }

    isSigning = true;
    signingStatusText = 'Đang ký PFX trên server...';
    update();

    ResponseModel responseModel = await dmsRepo.signWithPfx(
      documentId,
      pfxProfileSlug: selectedProfile?.slug ?? '',
      pfxPassword: trimmedPassword,
    );

    try {
      if (responseModel.statusCode != 200) {
        isSigning = false;
        signingStatusText = '';
        update();
        await AppAlert.error(
          _extractSignErrorMessage(responseModel),
          title: LocalStrings.signFailedTitle.tr,
        );
        return;
      }

      final payload = apiPayload(jsonDecode(responseModel.responseJson));
      final data = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : payload;
      final message = data['message']?.toString().isNotEmpty == true
          ? data['message'].toString()
          : 'Ký PFX thành công';

      isSigning = false;
      signingStatusText = '';
      await loadDocumentDetails(documentId);
      await AppAlert.success(
        message,
        title: LocalStrings.signSuccessTitle.tr,
      );
    } catch (_) {
      isSigning = false;
      signingStatusText = '';
      update();
      await AppAlert.error(
        LocalStrings.badResponseMsg.tr,
        title: LocalStrings.signFailedTitle.tr,
      );
    }
  }

  Future<void> rejectDocument(
    dynamic documentId, {
    required String reason,
  }) async {
    if (isSigning) {
      return;
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      await AppAlert.error(
        LocalStrings.enterRejectReason.tr,
        title: LocalStrings.rejectSignDocumentTitle.tr,
      );
      return;
    }

    isSigning = true;
    signingStatusText = 'Đang từ chối ký...';
    update();

    ResponseModel responseModel = await dmsRepo.rejectDocument(
      documentId,
      reason: trimmedReason,
    );

    try {
      if (responseModel.statusCode != 200) {
        isSigning = false;
        signingStatusText = '';
        update();
        await AppAlert.error(
          _extractSignErrorMessage(responseModel),
          title: LocalStrings.rejectSignDocumentTitle.tr,
        );
        return;
      }

      final payload = apiPayload(jsonDecode(responseModel.responseJson));
      final data = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'])
          : payload;
      final message = data['message']?.toString().isNotEmpty == true
          ? data['message'].toString()
          : LocalStrings.rejectSignSuccess.tr;

      isSigning = false;
      signingStatusText = '';
      await loadDocumentDetails(documentId);
      await AppAlert.success(
        message,
        title: LocalStrings.rejectSignDocumentTitle.tr,
      );
    } catch (_) {
      isSigning = false;
      signingStatusText = '';
      update();
      await AppAlert.error(
        LocalStrings.badResponseMsg.tr,
        title: LocalStrings.rejectSignDocumentTitle.tr,
      );
    }
  }

  /// Ưu tiên message từ body API (error.message) giống thông báo trên web.
  String _extractSignErrorMessage(ResponseModel responseModel) {
    if (responseModel.responseJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(responseModel.responseJson);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final error = map['error'];
          final fromError = error is Map ? error['message']?.toString() : null;
          final candidates = [
            fromError,
            map['message']?.toString(),
            map['data'] is Map
                ? (map['data'] as Map)['message']?.toString()
                : null,
            responseModel.message,
          ];
          for (final item in candidates) {
            final text = item?.trim() ?? '';
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      } catch (_) {}
    }

    if (responseModel.message.trim().isNotEmpty) {
      return responseModel.message.trim();
    }
    return LocalStrings.somethingWentWrong.tr;
  }
}

class DmsDocumentFilter {
  final String label;
  final String? docGroup;
  final String? filter;

  const DmsDocumentFilter({required this.label, this.docGroup, this.filter});
}
