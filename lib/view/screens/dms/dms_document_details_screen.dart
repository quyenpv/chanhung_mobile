import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/external_url_helper.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/dms_status_helper.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/controller/dms/dms_controller.dart';
import 'package:chanhung/data/model/dms/dms_document_model.dart';
import 'package:chanhung/data/repo/dms/dms_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/components/dialog/app_alert_dialog.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';

class DmsDocumentDetailsScreen extends StatefulWidget {
  const DmsDocumentDetailsScreen({super.key, required this.id});

  final dynamic id;

  @override
  State<DmsDocumentDetailsScreen> createState() =>
      _DmsDocumentDetailsScreenState();
}

class _DmsDocumentDetailsScreenState extends State<DmsDocumentDetailsScreen> {
  late final dynamic _documentId;

  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(DmsRepo(apiClient: Get.find()));
    final controller = Get.put(DmsController(dmsRepo: Get.find()));
    _documentId = _resolveDocumentId();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_hasDocumentId) {
        controller.loadDocumentDetails(_documentId);
      }
    });
  }

  bool get _hasDocumentId => _documentId?.toString().trim().isNotEmpty == true;

  dynamic _resolveDocumentId() {
    final directId = widget.id?.toString().trim();
    if (directId?.isNotEmpty == true) {
      return directId;
    }

    final routeParamId = Get.parameters['id']?.trim();
    if (routeParamId?.isNotEmpty == true) {
      return routeParamId;
    }

    final fragment = Uri.base.fragment;
    final queryStart = fragment.indexOf('?');
    if (queryStart < 0 || queryStart + 1 >= fragment.length) {
      return null;
    }

    return Uri.splitQueryString(fragment.substring(queryStart + 1))['id'];
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasDocumentId) {
      return Scaffold(
        appBar: CustomAppBar(title: LocalStrings.documentDetails.tr),
        drawer: const AppDrawer(),
        body: const NoDataWidget(),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.documentDetails.tr),
      drawer: const AppDrawer(),
      body: GetBuilder<DmsController>(
        builder: (controller) {
          if (controller.isDetailsLoading) {
            return const CustomLoader();
          }

          final document = controller.documentDetailsModel.data;
          if (document == null) {
            return const NoDataWidget();
          }

          return RefreshIndicator(
            color: Theme.of(context).primaryColor,
            onRefresh: () async {
              await controller.loadDocumentDetails(widget.id);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.space15),
              children: [
                _DocumentHeader(document: document),
                const SizedBox(height: Dimensions.space15),
                _DocumentInfo(document: document),
                const SizedBox(height: Dimensions.space15),
                _DocumentFiles(files: document.files),
                const SizedBox(height: Dimensions.space15),
                _SigningActions(document: document, controller: controller),
                const SizedBox(height: Dimensions.space15),
                _SignersList(signers: document.signers),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  const _DocumentHeader({required this.document});

  final DmsDocument document;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(document.status);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    document.docCode ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mediumLarge.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                  ),
                ),
                _Pill(
                    text: dmsStatusLabel(document.status), color: statusColor),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            Text(
              document.title ?? '',
              style: regularLarge.copyWith(
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            if (document.abstractText?.isNotEmpty == true) ...[
              const SizedBox(height: Dimensions.space10),
              Text(
                document.abstractText!,
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentFiles extends StatelessWidget {
  const _DocumentFiles({required this.files});

  final List<DmsDocumentFile> files;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    final signingFiles = files.where((file) => file.isSigningFile).toList();
    final attachments = files.where((file) => !file.isSigningFile).toList();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalStrings.documentFiles.tr, style: mediumLarge),
            if (signingFiles.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space12),
              Text(
                LocalStrings.signingFile.tr,
                style: regularSmall.copyWith(
                  color: ColorResources.blueGreyColor,
                ),
              ),
              const SizedBox(height: Dimensions.space8),
              ...signingFiles.map((file) => _DocumentFileRow(file: file)),
            ],
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space12),
              Text(
                LocalStrings.attachedFiles.tr,
                style: regularSmall.copyWith(
                  color: ColorResources.blueGreyColor,
                ),
              ),
              const SizedBox(height: Dimensions.space8),
              ...attachments.map((file) => _DocumentFileRow(file: file)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentFileRow extends StatelessWidget {
  const _DocumentFileRow({required this.file});

  final DmsDocumentFile file;

  @override
  Widget build(BuildContext context) {
    final ext = (file.fileExt ?? '').toLowerCase();
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: ColorResources.borderColor),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Row(
        children: [
          Icon(_fileIcon(ext), color: ColorResources.primaryColor, size: 22),
          const SizedBox(width: Dimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: regularDefault,
                ),
                if (ext.isNotEmpty || file.fileSize > 0)
                  Text(
                    [
                      if (ext.isNotEmpty) ext.toUpperCase(),
                      if (file.fileSize > 0) _formatFileSize(file.fileSize),
                    ].join(' - '),
                    style: lightSmall.copyWith(
                      color: ColorResources.blueGreyColor,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: LocalStrings.viewFile.tr,
            onPressed: () => _viewFile(file),
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: LocalStrings.downloadFile.tr,
            onPressed: () => _openFile(_directFileUrl(file, download: true)),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String? url) async {
    final opened = await openExternalUrl(_withAccessToken(url));
    if (!opened) {
      CustomSnackBar.error(errorList: [LocalStrings.openFileFailed.tr]);
    }
  }

  void _viewFile(DmsDocumentFile file) {
    final url = _withAccessToken(_directFileUrl(file));
    if (url == null || url.isEmpty) {
      CustomSnackBar.error(errorList: [LocalStrings.openFileFailed.tr]);
      return;
    }

    Get.toNamed(RouteHelper.dmsPdfViewerScreen, arguments: {
      'url': url,
      'title': file.fileName ?? LocalStrings.viewFile.tr,
    });
  }

  String? _directFileUrl(DmsDocumentFile file, {bool download = false}) {
    final documentId = file.documentId;
    final fileId = file.id;
    if (documentId?.isNotEmpty == true && fileId?.isNotEmpty == true) {
      final action = download ? 'download' : 'view';
      return '${UrlContainer.baseUrl}${UrlContainer.documentsUrl}/$documentId/files/$fileId/$action';
    }

    return download
        ? (file.downloadUrl ?? file.fileUrl)
        : (file.viewerUrl ?? file.fileUrl);
  }

  String? _withAccessToken(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return value;
    }

    final token = Get.find<ApiClient>()
            .sharedPreferences
            .getString(SharedPreferenceHelper.accessTokenKey) ??
        '';
    if (token.trim().isEmpty || !value.contains('/api/v1/')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'access_token': token,
    }).toString();
  }
}

class _SigningActions extends StatelessWidget {
  const _SigningActions({
    required this.document,
    required this.controller,
  });

  final DmsDocument document;
  final DmsController controller;

  @override
  Widget build(BuildContext context) {
    final permission = document.signPermission;
    final shouldShow = document.signers.isNotEmpty ||
        document.canSign ||
        permission?.signer != null;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final canStartEsign = permission?.canStartEsign == true;
    final hasToken = permission?.hasEsignToken == true;
    final hasPfxCertificate = permission?.hasPfxCertificate == true;
    final hasPfxSavedPassword = permission?.hasPfxSavedPassword == true;
    final selectedPfxProfile = permission?.selectedPfxProfile;
    final signer = permission?.signer;
    final signerStatus = (signer?.status ?? '').toLowerCase();
    final alreadyHandled = signerStatus == 'signed' ||
        signerStatus == 'rejected' ||
        signerStatus == 'cancelled';
    final statusText = document.canSign && !alreadyHandled
        ? LocalStrings.waitingForSignature.tr
        : (signerStatus.isNotEmpty
            ? dmsStatusLabel(signerStatus)
            : LocalStrings.signingUnavailable.tr);
    final statusColor = document.canSign && !alreadyHandled
        ? ColorResources.yellowColor
        : _statusColor(signerStatus);
    final canAct = document.canSign &&
        !alreadyHandled &&
        !controller.isSigning &&
        (permission?.canSign == true);
    final canSubmitPfx = canAct && hasPfxCertificate;
    final canSubmitEsign = canAct && canStartEsign;
    // Tá»« chá»‘i cÃ¹ng Ä‘iá»u kiá»‡n vá»›i cÃ²n quyá»n kÃ½ (Ä‘Ã£ signed/rejected thÃ¬ canAct=false).
    final canReject = canAct;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(LocalStrings.digitalSignature.tr,
                      style: mediumLarge),
                ),
                _Pill(text: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            if (permission?.message?.isNotEmpty == true)
              Text(
                permission!.message!,
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor),
              ),
            if (permission?.esignCert?.certName?.isNotEmpty == true) ...[
              const SizedBox(height: Dimensions.space8),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 18, color: ColorResources.greenColor),
                  const SizedBox(width: Dimensions.space8),
                  Expanded(
                    child: Text(
                      permission!.esignCert!.certName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: regularSmall,
                    ),
                  ),
                ],
              ),
            ] else if (document.canSign && !hasToken) ...[
              const SizedBox(height: Dimensions.space8),
              Text(
                LocalStrings.esignNotConnected.tr,
                style: regularSmall.copyWith(color: ColorResources.redColor),
              ),
            ],
            if (selectedPfxProfile?.hasCertificate == true) ...[
              const SizedBox(height: Dimensions.space8),
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined,
                      size: 18, color: ColorResources.greenColor),
                  const SizedBox(width: Dimensions.space8),
                  Expanded(
                    child: Text(
                      '${LocalStrings.serverPfxCertificate.tr}: ${selectedPfxProfile?.label ?? 'PFX'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: regularSmall,
                    ),
                  ),
                ],
              ),
            ] else if (document.canSign && !hasPfxCertificate) ...[
              const SizedBox(height: Dimensions.space8),
              Text(
                LocalStrings.pfxNotConfigured.tr,
                style: regularSmall.copyWith(color: ColorResources.redColor),
              ),
            ],
            if (document.canSign && hasPfxCertificate) ...[
              const SizedBox(height: Dimensions.space8),
              Text(
                hasPfxSavedPassword &&
                        selectedPfxProfile?.hasSavedPassword == true
                    ? LocalStrings.pfxPasswordOptionalHint.tr
                    : LocalStrings.pfxPasswordRequiredHint.tr,
                style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
              ),
            ],
            if (controller.isSigning) ...[
              const SizedBox(height: Dimensions.space12),
              const LinearProgressIndicator(minHeight: 3),
              if (controller.signingStatusText.isNotEmpty) ...[
                const SizedBox(height: Dimensions.space8),
                Text(
                  controller.signingStatusText,
                  style:
                      regularSmall.copyWith(color: ColorResources.primaryColor),
                ),
              ],
            ],
            const SizedBox(height: Dimensions.space12),
            Wrap(
              spacing: Dimensions.space8,
              runSpacing: Dimensions.space8,
              children: [
                ElevatedButton.icon(
                  onPressed: canSubmitPfx
                      ? () => controller.startPfxSigning(document.id)
                      : null,
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: Text(LocalStrings.signWithPfx.tr),
                ),
                OutlinedButton.icon(
                  onPressed: canSubmitEsign
                      ? () => _confirmAndStartEsign(context)
                      : null,
                  icon: const Icon(Icons.draw_outlined, size: 18),
                  label: Text(LocalStrings.signWithEsign.tr),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorResources.colorRed,
                    side: const BorderSide(color: ColorResources.colorRed),
                  ),
                  onPressed:
                      canReject ? () => _confirmAndReject(context) : null,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(LocalStrings.rejectSignDocument.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndStartEsign(BuildContext context) async {
    final shouldSign = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LocalStrings.confirmSignDocument.tr),
          content: Text(LocalStrings.confirmSignDocumentMessage.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LocalStrings.no.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(LocalStrings.yes.tr),
            ),
          ],
        );
      },
    );

    if (shouldSign == true) {
      await controller.startEsignSigning(document.id);
    }
  }

  Future<void> _confirmAndReject(BuildContext context) async {
    final reasonController = TextEditingController();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LocalStrings.rejectSignDocumentTitle.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalStrings.confirmRejectSignMessage.tr),
              const SizedBox(height: Dimensions.space15),
              Text(
                LocalStrings.rejectSignReasonLabel.tr,
                style: mediumDefault,
              ),
              const SizedBox(height: Dimensions.space8),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: LocalStrings.rejectSignReasonHint.tr,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LocalStrings.no.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResources.colorRed,
                foregroundColor: ColorResources.colorWhite,
              ),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  AppAlert.error(LocalStrings.enterRejectReason.tr);
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(LocalStrings.rejectSignDocument.tr),
            ),
          ],
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (shouldReject == true) {
      await controller.rejectDocument(document.id, reason: reason);
    }
  }
}

class _DocumentInfo extends StatelessWidget {
  const _DocumentInfo({required this.document});

  final DmsDocument document;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRowData>[
      _InfoRowData(LocalStrings.documentCode.tr, document.docCode),
      _InfoRowData(LocalStrings.documentType.tr, document.typeTitle),
      _InfoRowData(LocalStrings.organization.tr, document.organization),
      _InfoRowData(LocalStrings.drafter.tr, document.drafterName),
      _InfoRowData(LocalStrings.issuedDate.tr, document.issuedDate),
      _InfoRowData(LocalStrings.arrivalDate.tr, document.arrivalDate),
      _InfoRowData(LocalStrings.deadline.tr, document.deadline),
      _InfoRowData(
          LocalStrings.attachments.tr,
          document.attachmentCount > 0
              ? document.attachmentCount.toString()
              : ''),
    ].where((row) => row.value?.isNotEmpty == true).toList();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          children: rows
              .map((row) => _DetailRow(label: row.label, value: row.value!))
              .toList(),
        ),
      ),
    );
  }
}

class _SignersList extends StatelessWidget {
  const _SignersList({required this.signers});

  final List<DmsSigner> signers;

  @override
  Widget build(BuildContext context) {
    if (signers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocalStrings.signers.tr, style: mediumLarge),
            const SizedBox(height: Dimensions.space10),
            ...signers.map((signer) => Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.space10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            ColorResources.primaryColor.withValues(alpha: 0.12),
                        child: Text(
                          signer.signingOrder ?? '',
                          style: regularSmall.copyWith(
                              color: ColorResources.primaryColor),
                        ),
                      ),
                      const SizedBox(width: Dimensions.space10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signer.userName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: regularDefault,
                            ),
                            Text(
                              dmsSignerActionLabel(signer.actionType),
                              style: lightSmall.copyWith(
                                color: ColorResources.blueGreyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _Pill(
                        text: dmsStatusLabel(signer.status),
                        color: _statusColor(signer.status),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: regularDefault.copyWith(
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(
        text,
        style: lightSmall.copyWith(color: color),
      ),
    );
  }
}

class _InfoRowData {
  final String label;
  final String? value;

  const _InfoRowData(this.label, this.value);
}

IconData _fileIcon(String ext) {
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icons.image_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

String _formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

Color _statusColor(String? status) {
  switch (status) {
    case 'published':
    case 'completed':
    case 'signed':
      return ColorResources.greenColor;
    case 'pending':
    case 'processing':
      return ColorResources.yellowColor;
    case 'cancelled':
    case 'rejected':
      return ColorResources.redColor;
    default:
      return ColorResources.primaryColor;
  }
}
