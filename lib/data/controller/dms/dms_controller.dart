import 'dart:convert';

import 'package:get/get.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/data/model/dms/dms_document_model.dart';
import 'package:chanhung/data/model/global/api_response_payload.dart';
import 'package:chanhung/data/model/global/response_model/response_model.dart';
import 'package:chanhung/data/repo/dms/dms_repo.dart';
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
        CustomSnackBar.error(errorList: [
          responseModel.message.isNotEmpty
              ? responseModel.message
              : LocalStrings.somethingWentWrong.tr
        ]);
        isSigning = false;
        update();
        return;
      }

      final startPayload = apiPayload(jsonDecode(responseModel.responseJson));
      final startData = startPayload['data'] is Map
          ? Map<String, dynamic>.from(startPayload['data'])
          : startPayload;
      final transactionId = startData['transaction_id']?.toString() ?? '';
      if (transactionId.isEmpty) {
        CustomSnackBar.error(errorList: [
          startData['message']?.toString() ?? LocalStrings.badResponseMsg.tr
        ]);
        isSigning = false;
        update();
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
          CustomSnackBar.success(successList: ['Ký eSign thành công']);
          return;
        }

        if (status == 'FAILED' || status == 'REJECTED' || status == 'EXPIRED') {
          isSigning = false;
          signingStatusText = '';
          CustomSnackBar.error(errorList: [
            statusData['message']?.toString().isNotEmpty == true
                ? statusData['message'].toString()
                : 'Yêu cầu ký eSign không thành công'
          ]);
          update();
          return;
        }
      }

      isSigning = false;
      signingStatusText = '';
      CustomSnackBar.error(errorList: [
        'Chưa nhận được xác nhận eSign. Vui lòng kiểm tra lại sau.'
      ]);
      update();
    } catch (_) {
      isSigning = false;
      signingStatusText = '';
      CustomSnackBar.error(errorList: [LocalStrings.badResponseMsg.tr]);
      update();
    }
  }

  Future<void> startPfxSigning(dynamic documentId) async {
    if (isSigning) {
      return;
    }

    final permission = documentDetailsModel.data?.signPermission;
    final selectedProfile = permission?.selectedPfxProfile;
    if (selectedProfile?.hasCertificate != true) {
      CustomSnackBar.error(errorList: [LocalStrings.pfxNotConfigured.tr]);
      return;
    }
    if (selectedProfile?.hasSavedPassword != true) {
      CustomSnackBar.error(errorList: [LocalStrings.pfxPasswordNotSaved.tr]);
      return;
    }

    isSigning = true;
    signingStatusText = 'Đang ký PFX trên server...';
    update();

    ResponseModel responseModel = await dmsRepo.signWithPfx(
      documentId,
      pfxProfileSlug: selectedProfile?.slug ?? '',
    );

    try {
      if (responseModel.statusCode != 200) {
        CustomSnackBar.error(errorList: [
          responseModel.message.isNotEmpty
              ? responseModel.message
              : LocalStrings.somethingWentWrong.tr
        ]);
        isSigning = false;
        signingStatusText = '';
        update();
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
      CustomSnackBar.success(successList: [message]);
    } catch (_) {
      isSigning = false;
      signingStatusText = '';
      CustomSnackBar.error(errorList: [LocalStrings.badResponseMsg.tr]);
      update();
    }
  }
}

class DmsDocumentFilter {
  final String label;
  final String? docGroup;
  final String? filter;

  const DmsDocumentFilter({required this.label, this.docGroup, this.filter});
}
