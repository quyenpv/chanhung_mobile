import 'dart:convert';
import 'package:chanhung/core/helper/external_url_helper.dart';
import 'package:chanhung/core/helper/shared_preference_helper.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/payment_request/payment_request_controller.dart';
import 'package:chanhung/data/model/payment_request/payment_request_model.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/dialog/app_alert_dialog.dart';
import 'package:chanhung/view/components/dialog/pfx_password_dialog.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/components/snack_bar/show_custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentRequestDetailsScreen extends StatefulWidget {
  final dynamic id;
  const PaymentRequestDetailsScreen({super.key, this.id});

  @override
  State<PaymentRequestDetailsScreen> createState() =>
      _PaymentRequestDetailsScreenState();
}

class _PaymentRequestDetailsScreenState
    extends State<PaymentRequestDetailsScreen> {
  late final int? _requestId;
  bool isPermissionLoading = false;
  Map<String, dynamic>? signPermissionData;

  @override
  void initState() {
    _requestId = _resolveRequestId();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_requestId != null) {
        final controller = Get.find<PaymentRequestsController>();
        controller.loadDetails(_requestId).then((_) {
          if (mounted && controller.details?.canSign == true) {
            fetchSignPermission();
          }
        });
      }
    });
  }

  int? _resolveRequestId() {
    final directId = widget.id?.toString().trim();
    if (directId != null && directId.isNotEmpty) {
      return int.tryParse(directId);
    }
    final argument = Get.arguments;
    if (argument != null) {
      return int.tryParse(argument.toString().trim());
    }
    return int.tryParse(Get.parameters['id']?.trim() ?? '');
  }

  Future<void> fetchSignPermission() async {
    if (_requestId == null) return;
    if (!mounted) return;
    setState(() {
      isPermissionLoading = true;
    });
    try {
      final controller = Get.find<PaymentRequestsController>();
      final response = await controller.repo.getSignPermission(_requestId);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.responseJson);
        if (!mounted) return;
        setState(() {
          if (decoded['success'] == true &&
              decoded['data'] != null &&
              decoded['data']['permission'] != null) {
            signPermissionData = decoded['data']['permission'];
          } else if (decoded['permission'] != null) {
            signPermissionData = decoded['permission'];
          }
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          isPermissionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_requestId == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: "Chi tiết yêu cầu"),
        drawer: const AppDrawer(),
        body: const NoDataWidget(),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: "Chi tiết yêu cầu"),
      drawer: const AppDrawer(),
      body: GetBuilder<PaymentRequestsController>(
        builder: (controller) {
          if (controller.isDetailsLoading) {
            return const CustomLoader();
          }

          final details = controller.details;
          if (details == null) {
            return const NoDataWidget();
          }

          final currency = controller.currency ?? 'đ';
          final formatter =
              NumberFormat.currency(locale: 'vi_VN', symbol: currency);

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadDetails(_requestId);
              if (controller.details?.canSign == true) {
                await fetchSignPermission();
              }
            },
            color: Theme.of(context).primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    _buildHeaderCard(details),
                    const SizedBox(height: Dimensions.space12),

                    // Base info
                    _buildBaseInfoCard(details, formatter),
                    const SizedBox(height: Dimensions.space12),

                    // Lines item
                    if (details.lines != null && details.lines!.isNotEmpty) ...[
                      _buildLinesCard(details.lines!, formatter),
                      const SizedBox(height: Dimensions.space12),
                    ],

                    // Advance Settlement Info (if matching request type)
                    if (details.requestType == 'advance_settlement') ...[
                      _buildSettlementCard(details, formatter),
                      const SizedBox(height: Dimensions.space12),
                    ],

                    // Files & attachments card
                    if ((details.files != null && details.files!.isNotEmpty) ||
                        (details.attachments != null &&
                            details.attachments!.isNotEmpty)) ...[
                      _buildFilesCard(details),
                      const SizedBox(height: Dimensions.space12),
                    ],

                    // Signers status checklist
                    if (details.signers != null &&
                        details.signers!.isNotEmpty) ...[
                      _buildSignersCard(details.signers!),
                      const SizedBox(height: Dimensions.space12),
                    ],

                    // Digital signature trigger floating panel
                    if (details.canSign == true) ...[
                      _buildSignatureActionCard(controller, details),
                      const SizedBox(height: Dimensions.space12),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(PaymentRequestDetailModel details) {
    final statusColor = _statusColor(details.status);
    final statusText = _statusText(details.status ?? '');
    final typeText = details.requestType == 'advance_settlement'
        ? 'Quyết toán hoàn ứng'
        : 'Đề nghị thanh toán/tạm ứng';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                details.requestCode ?? 'N/A',
                style:
                    semiBoldLarge.copyWith(color: ColorResources.primaryColor),
              ),
              _buildStatusPill(statusText, statusColor),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Text(
            details.title ?? '',
            style: boldLarge.copyWith(fontSize: 16),
          ),
          const SizedBox(height: Dimensions.space8),
          Text(
            typeText,
            style: regularSmall.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseInfoCard(
      PaymentRequestDetailModel details, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Thông tin chung",
              style: boldLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.space8),
          _buildInfoRow("Ngày lập:", details.requestDate ?? '-'),
          _buildInfoRow("Người đề nghị:",
              "${details.requesterName ?? ''} (${details.requesterRoleTitle ?? ''})"),
          _buildInfoRow("Bộ phận:", details.departmentTitle ?? '-'),
          _buildInfoRow(
              "Đơn vị thành viên:",
              details.companyName != null && details.companyCode != null
                  ? "${details.companyName} (${details.companyCode})"
                  : (details.companyName ?? '-')),
          _buildInfoRow("Nguồn vốn:", details.fundSource ?? '-'),
          _buildInfoRow("Mã ngân sách:", details.budgetCode ?? '-'),
          _buildInfoRow("Hạn thanh toán:", details.paymentDeadline ?? '-'),
          _buildInfoRow(
              "Phương thức thanh toán:", details.paymentMethod ?? '-'),
          _buildInfoRow(
              "Tổng số tiền:", formatter.format(details.totalAmount ?? 0.0),
              isBoldValue: true, valueColor: ColorResources.primaryColor),
          _buildInfoRow("Số tiền bằng chữ:", details.amountInWords ?? '-'),
          const SizedBox(height: Dimensions.space10),
          const Text("Thông tin thụ hưởng", style: boldLarge),
          const SizedBox(height: Dimensions.space5),
          _buildInfoRow("Đối tượng:", details.beneficiaryPartyType ?? '-'),
          _buildInfoRow("Tên thụ hưởng:", details.beneficiaryName ?? '-'),
          _buildInfoRow("Ngân hàng:", details.beneficiaryBank ?? '-'),
          _buildInfoRow("Số tài khoản:", details.beneficiaryAccount ?? '-'),
        ],
      ),
    );
  }

  Widget _buildLinesCard(
      List<PaymentRequestLine> lines, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chi tiết khoản mục đề nghị",
              style: boldLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.space8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lines.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final line = lines[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: Dimensions.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: ColorResources.primaryColor
                              .withValues(alpha: 0.1),
                          child: Text(
                            "${line.lineNo ?? (index + 1)}",
                            style: lightSmall.copyWith(
                                fontSize: 10,
                                color: ColorResources.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: Dimensions.space8),
                        Expanded(
                          child: Text(
                            line.title ?? '',
                            style: mediumDefault.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 28.0),
                      child: Column(
                        children: [
                          _buildDetailRowItem("Số lượng:",
                              "${line.quantity} ${line.unitType ?? ''}"),
                          _buildDetailRowItem(
                              "Đơn giá:", formatter.format(line.rate ?? 0.0)),
                          _buildDetailRowItem("Thành tiền:",
                              formatter.format(line.amount ?? 0.0)),
                          _buildDetailRowItem("Thuế suất:",
                              "${line.taxPercentage ?? 0}% (${formatter.format(line.taxAmount ?? 0.0)})"),
                          _buildDetailRowItem("Tổng tiền:",
                              formatter.format(line.totalAmount ?? 0.0),
                              isBold: true),
                          if (line.note != null && line.note!.isNotEmpty)
                            _buildDetailRowItem("Ghi chú:", line.note!),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(
      PaymentRequestDetailModel details, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Thông tin quyết toán hoàn ứng",
              style: boldLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.space8),
          _buildInfoRow("Kỳ quyết toán:",
              "Tháng ${details.settlementPeriodMonth ?? '-'}/${details.settlementPeriodYear ?? '-'}"),
          _buildInfoRow("Số tiền tạm ứng các kỳ trước chưa thanh toán:",
              formatter.format(details.settlementPreviousAmount ?? 0.0)),
          _buildInfoRow("Số tiền tạm ứng kỳ này:",
              formatter.format(details.settlementAdvanceAmount ?? 0.0)),
          _buildInfoRow("Tổng số tiền tạm ứng:",
              formatter.format(details.settlementTotalAdvanceAmount ?? 0.0),
              isBoldValue: true),
          _buildInfoRow("Số tiền thực chi theo hóa đơn:",
              formatter.format(details.settlementSpentAmount ?? 0.0),
              isBoldValue: true),
          _buildInfoRow("Số tiền thừa nộp lại quỹ:",
              formatter.format(details.settlementReturnAmount ?? 0.0)),
          _buildInfoRow("Số tiền thiếu đề nghị thanh toán thêm:",
              formatter.format(details.settlementExtraPaymentAmount ?? 0.0),
              valueColor: Colors.red),
          if (details.settlementSources != null &&
              details.settlementSources!.isNotEmpty) ...[
            const SizedBox(height: Dimensions.space15),
            const Text("Nguồn thanh toán tạm ứng", style: boldLarge),
            const SizedBox(height: Dimensions.space8),
            ...details.settlementSources!.map((src) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(src.sourceCode ?? '',
                                style: mediumDefault.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Text(formatter.format(src.amount ?? 0.0),
                                style: boldLarge.copyWith(
                                    color: ColorResources.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(src.sourceTitle ?? '', style: regularSmall),
                        if (src.sourceDate != null)
                          Text("Ngày: ${src.sourceDate}", style: lightSmall),
                      ],
                    ),
                  ),
                )),
          ],
          if (details.settlementExpenses != null &&
              details.settlementExpenses!.isNotEmpty) ...[
            const SizedBox(height: Dimensions.space15),
            const Text("Chi tiết chứng từ thực chi", style: boldLarge),
            const SizedBox(height: Dimensions.space8),
            ...details.settlementExpenses!.map((exp) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Số HĐ: ${exp.voucherNo ?? ''}",
                                style: mediumDefault.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Text(formatter.format(exp.amount ?? 0.0),
                                style: boldLarge.copyWith(
                                    color: ColorResources.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(exp.description ?? '', style: regularSmall),
                        if (exp.voucherDate != null)
                          Text("Ngày: ${exp.voucherDate}", style: lightSmall),
                        if (exp.note != null && exp.note!.isNotEmpty)
                          Text("Ghi chú: ${exp.note}", style: lightSmall),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFilesCard(PaymentRequestDetailModel details) {
    final signingFiles =
        details.files?.where((f) => f.isSigningFile == true).toList() ?? [];
    final otherFiles =
        details.files?.where((f) => f.isSigningFile != true).toList() ?? [];
    final attachments = details.attachments ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tài liệu & đính kèm",
              style: boldLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.space8),
          if (signingFiles.isNotEmpty) ...[
            Text("File trình ký",
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor)),
            const SizedBox(height: 6),
            ...signingFiles.map((file) => _buildFileRow(
                file.fileName ?? '', file.fileExt ?? 'pdf', file.fileSize ?? 0,
                onView: () => _viewPrFile(file),
                onDownload: () =>
                    _openExternalFileUrl(file.downloadUrl ?? file.serveUrl))),
            const SizedBox(height: 12),
          ],
          if (otherFiles.isNotEmpty || attachments.isNotEmpty) ...[
            Text("File phụ lục đính kèm",
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor)),
            const SizedBox(height: 6),
            ...otherFiles.map((file) => _buildFileRow(
                file.fileName ?? '', file.fileExt ?? 'pdf', file.fileSize ?? 0,
                onView: () => _viewPrFile(file),
                onDownload: () =>
                    _openExternalFileUrl(file.downloadUrl ?? file.serveUrl))),
            ...attachments.map((file) => _buildFileRow(file.fileName ?? '',
                file.filePath?.split('.').last ?? 'pdf', file.fileSize ?? 0,
                onView: null,
                onDownload: () => _openExternalFileUrl(file.filePath))),
          ],
        ],
      ),
    );
  }

  Widget _buildFileRow(String name, String ext, int size,
      {VoidCallback? onView, required VoidCallback onDownload}) {
    final displayExt = ext.toLowerCase();
    final formattedSize = size > 0 ? _formatFileSize(size) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space8),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space10, vertical: Dimensions.space8),
      decoration: BoxDecoration(
        border: Border.all(color: ColorResources.borderColor),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Row(
        children: [
          Icon(_fileIcon(displayExt),
              color: ColorResources.primaryColor, size: 22),
          const SizedBox(width: Dimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: regularDefault,
                ),
                if (displayExt.isNotEmpty || formattedSize.isNotEmpty)
                  Text(
                    [
                      if (displayExt.isNotEmpty) displayExt.toUpperCase(),
                      if (formattedSize.isNotEmpty) formattedSize,
                    ].join(' - '),
                    style: lightSmall.copyWith(
                        color: ColorResources.blueGreyColor),
                  ),
              ],
            ),
          ),
          if (onView != null)
            IconButton(
              tooltip: "Xem file",
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined),
            ),
          IconButton(
            tooltip: "Tải file",
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }

  void _viewPrFile(PaymentRequestFile file) {
    final url = _withAccessToken(file.viewerUrl ?? file.serveUrl);
    if (url == null || url.isEmpty) {
      CustomSnackBar.error(errorList: ["Không thể mở file"]);
      return;
    }

    Get.toNamed(RouteHelper.dmsPdfViewerScreen, arguments: {
      'url': url,
      'title': file.fileName ?? "Xem file",
    });
  }

  Future<void> _openExternalFileUrl(String? url) async {
    final fullUrl = _withAccessToken(url);
    if (fullUrl == null || fullUrl.isEmpty) {
      CustomSnackBar.error(errorList: ["Không thể tải file"]);
      return;
    }
    final opened = await openExternalUrl(fullUrl);
    if (!opened) {
      CustomSnackBar.error(errorList: ["Không thể mở file"]);
    }
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

  Widget _buildSignersCard(List<PaymentRequestSigner> signers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tiến trình ký duyệt",
              style: boldLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space8),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.space8),
          ...signers.map((signer) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.space10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          ColorResources.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        "${signer.signingOrder ?? ''}",
                        style: regularSmall.copyWith(
                            color: ColorResources.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: Dimensions.space10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(signer.userName ?? '',
                              style: mediumDefault.copyWith(
                                  fontWeight: FontWeight.bold)),
                          Text(signer.roleTitle ?? '',
                              style: lightSmall.copyWith(
                                  color: ColorResources.blueGreyColor)),
                          if (signer.note != null && signer.note!.isNotEmpty)
                            Text("Ghi chú: ${signer.note}",
                                style: lightSmall.copyWith(
                                    color: Colors.blueGrey,
                                    fontStyle: FontStyle.italic)),
                          if (signer.signedAt != null)
                            Text("Ngày ký: ${signer.signedAt}",
                                style: lightSmall.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    _buildSignerStatusPill(signer.status ?? ''),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSignerStatusPill(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'signed':
        color = ColorResources.greenColor;
        text = 'Đã ký';
        break;
      case 'waiting':
        color = Colors.orange;
        text = 'Chờ ký';
        break;
      case 'pending':
        color = Colors.grey;
        text = 'Chưa đến lượt';
        break;
      case 'rejected':
        color = ColorResources.redColor;
        text = 'Bác bỏ';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(
        text,
        style: lightSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSignatureActionCard(
      PaymentRequestsController controller, PaymentRequestDetailModel details) {
    if (isPermissionLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final alertMessage =
        signPermissionData?['message'] ?? 'Sẵn sàng ký duyệt hồ sơ.';
    final canSign =
        signPermissionData?['can_sign'] == true || details.canSign == true;
    final canReject = signPermissionData?['can_reject'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.orange.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "Yêu cầu bạn ký duyệt",
                style: boldLarge.copyWith(color: Colors.orange.shade900),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space8),
          Text(alertMessage,
              style: regularSmall.copyWith(color: Colors.grey.shade800)),
          const SizedBox(height: Dimensions.space12),
          if (controller.isSigning) ...[
            const SizedBox(height: Dimensions.space5),
            const LinearProgressIndicator(),
            const SizedBox(height: Dimensions.space8),
            const Text("Đang thực hiện quy trình ký duyệt số...",
                style: TextStyle(fontStyle: FontStyle.italic)),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResources.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: canSign
                        ? () => _showSigningBottomSheet(
                            context, controller, details)
                        : null,
                    icon: const Icon(Icons.draw, color: Colors.white),
                    label: const Text("Ký duyệt hồ sơ",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (canReject) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorResources.colorRed,
                        side: const BorderSide(color: ColorResources.colorRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () =>
                          _confirmAndReject(context, controller, details),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        LocalStrings.rejectSignDocument.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            )
          ]
        ],
      ),
    );
  }

  Future<void> _confirmAndReject(
    BuildContext context,
    PaymentRequestsController controller,
    PaymentRequestDetailModel details,
  ) async {
    final reasonController = TextEditingController();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LocalStrings.rejectSignPaymentRequestTitle.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalStrings.confirmRejectPaymentRequestMessage.tr),
              const SizedBox(height: Dimensions.space15),
              Text(
                LocalStrings.rejectSignReasonLabel.tr,
                style: mediumDefault,
              ),
              const SizedBox(height: Dimensions.space8),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: LocalStrings.rejectSignPaymentRequestReasonHint.tr,
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
      final ok = await controller.rejectSigning(
        details.id ?? _requestId!,
        reason: reason,
      );
      if (ok && mounted) {
        setState(() {
          signPermissionData = null;
        });
      }
    }
  }

  void _showSigningBottomSheet(BuildContext context,
      PaymentRequestsController controller, PaymentRequestDetailModel details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) {
        return _SigningModal(
          controller: controller,
          details: details,
          permissionData: signPermissionData,
          onSuccess: () {
            Navigator.of(builderContext).pop();
            // refresh data
            controller.loadDetails(_requestId!).then((_) {
              if (mounted && controller.details?.canSign == true) {
                fetchSignPermission();
              }
            });
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBoldValue = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isBoldValue
                  ? boldLarge.copyWith(
                      color: valueColor ??
                          Theme.of(context).textTheme.bodyMedium?.color)
                  : regularDefault.copyWith(
                      color: valueColor ??
                          Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowItem(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(label,
              style: lightSmall.copyWith(color: ColorResources.blueGreyColor)),
          const SizedBox(width: 4),
          Text(value,
              style: isBold ? boldLarge.copyWith(fontSize: 12) : regularSmall),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(
        text,
        style: lightSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'signing':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'more_info_required':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Nháp';
      case 'signing':
        return 'Chờ ký';
      case 'completed':
        return 'Đã duyệt';
      case 'paid':
        return 'Đã chi';
      case 'rejected':
        return 'Từ chối';
      case 'more_info_required':
        return 'Cần bổ sung';
      default:
        return status;
    }
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
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
    if (bytes <= 0) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

class _SigningModal extends StatefulWidget {
  final PaymentRequestsController controller;
  final PaymentRequestDetailModel details;
  final Map<String, dynamic>? permissionData;
  final VoidCallback onSuccess;

  const _SigningModal({
    required this.controller,
    required this.details,
    required this.permissionData,
    required this.onSuccess,
  });

  @override
  State<_SigningModal> createState() => _SigningModalState();
}

class _SigningModalState extends State<_SigningModal> {
  int _selectedTab = 0; // 0 = PFX, 1 = eSign
  String _selectedPfxSlug = 'default';
  final _passwordController = TextEditingController();
  final _instructionController = TextEditingController();
  final _keywordController = TextEditingController();

  bool _isLocalSigning = false;
  String _localSigningProgressText = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Default PFX slug from backend suggestions
    final suggested =
        widget.permissionData?['suggested_pfx_profile_slug']?.toString();
    if (suggested != null && suggested.isNotEmpty) {
      _selectedPfxSlug = suggested;
    }

    // Default comment keyword as visual signature order
    final mySigningOrder = widget.permissionData?['signer']?['signing_order'];
    if (mySigningOrder != null) {
      _keywordController.text = mySigningOrder.toString();
    } else {
      _keywordController.text = "1";
    }

    _instructionController.text = "Đồng ý phê duyệt";

    final hasPfx = widget.permissionData?['has_pfx_certificate'] == true;
    final hasEsign = widget.permissionData?['has_esign_token'] == true;

    if (!hasPfx && hasEsign) {
      _selectedTab = 1;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _passwordController.dispose();
    _instructionController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesRaw = widget.permissionData?['pfx_profiles'];
    List<Map<String, dynamic>> profiles = [];
    if (profilesRaw is List) {
      profiles = profilesRaw.map((p) => Map<String, dynamic>.from(p)).toList();
    }

    final hasPfx = widget.permissionData?['has_pfx_certificate'] == true;
    final hasEsign = widget.permissionData?['has_esign_token'] == true;
    final esignCertName =
        widget.permissionData?['esign_cert']?['certName']?.toString() ??
            'eSign';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(Dimensions.space20),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.space15),
            Text(
              "Xác thực chữ ký số",
              style: boldLarge.copyWith(
                  fontSize: 18, color: ColorResources.primaryColor),
            ),
            const SizedBox(height: Dimensions.space15),

            // Tab Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? ColorResources.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Chứng thư PFX Server",
                          style: boldLarge.copyWith(
                            color: _selectedTab == 0
                                ? ColorResources.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? ColorResources.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "MISA eSign (Remote)",
                          style: boldLarge.copyWith(
                            color: _selectedTab == 1
                                ? ColorResources.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space20),

            if (_isLocalSigning) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: Dimensions.space15),
                    Text(
                      _localSigningProgressText,
                      textAlign: TextAlign.center,
                      style: boldLarge.copyWith(
                          color: ColorResources.primaryColor),
                    ),
                    const SizedBox(height: 10),
                    const Text("Vui lòng không đóng cửa sổ này...",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ] else ...[
              if (_selectedTab == 0) ...[
                // PFX Tab Layout
                if (!hasPfx)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Bạn chưa cấu hình chứng thư PFX trên hệ thống. Vui lòng đăng nhập bản Web để tải lên tệp PFX.",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  // Dropdown to select PFX profile
                  if (profiles.isNotEmpty) ...[
                    const Text("Chọn chứng thư số PFX",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPfxSlug,
                          isExpanded: true,
                          items: profiles.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['slug']?.toString() ?? 'default',
                              child: Text(p['label']?.toString() ?? 'PFX'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPfxSlug = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.space15),
                  ],

                  // Luôn hiện ô mật khẩu (giống DMS) — không ẩn khi has_pfx_saved_password
                  // để tránh gửi mật khẩu rỗng khi bản lưu trên server hỏng.
                  const Text("Mật khẩu chứng thư (*)",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Nhập mật khẩu tệp PFX của bạn",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: Dimensions.space15),
                ],
              ] else ...[
                // eSign Tab Layout
                if (!hasEsign)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Bạn chưa kết nối với tài khoản MISA eSign. Vui lòng kết nối MISA eSign trên phiên bản Web.",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  // Connected eSign details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Đã kết nối chứng thư số MISA eSign:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(esignCertName,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.space15),
                ],
              ],

              // Shared fields: Instruction and Comment Keyword
              const Text("Ý kiến / Chỉ thị ký",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _instructionController,
                decoration: InputDecoration(
                  hintText: "Nhập ý kiến duyệt hồ sơ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: Dimensions.space15),

              const Text("Từ khóa vị trí ký (PDF comment)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _keywordController,
                decoration: InputDecoration(
                  hintText: "Để trống = thứ tự hiển thị tự động",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: Dimensions.space25),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        const Text("Hủy", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResources.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _selectedTab == 0
                        ? (hasPfx ? _executePfxSign : null)
                        : (hasEsign ? _executeEsignSign : null),
                    child: const Text("Xác nhận ký",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    ),
  ),
);
}

  Future<void> _executePfxSign() async {
    var pwd = _passwordController.text.trim();
    // Bắt buộc có mật khẩu trước khi gọi API (mọi máy) — giống DMS.
    if (pwd.isEmpty) {
      final typed = await PfxPasswordDialog.show(context: context);
      if (typed == null) {
        return;
      }
      pwd = typed.trim();
    }
    if (pwd.isEmpty) {
      await AppAlert.error(
        LocalStrings.enterPfxPassword.tr,
        title: LocalStrings.signFailedTitle.tr,
      );
      return;
    }

    final keyword = _keywordController.text.trim();

    setState(() {
      _isLocalSigning = true;
      _localSigningProgressText = "Đang truyền tệp PFX và ký trên server...";
    });

    final success = await widget.controller.submitPfxSignature(
      widget.details.id ?? 0,
      _selectedPfxSlug,
      pwd,
      _instructionController.text,
      keyword,
    );

    if (_isDisposed) return;

    setState(() {
      _isLocalSigning = false;
    });

    if (success) {
      widget.onSuccess();
    }
  }

  Future<void> _executeEsignSign() async {
    final keyword = _keywordController.text.trim();

    setState(() {
      _isLocalSigning = true;
      _localSigningProgressText = "Khởi tạo yêu cầu MISA eSign...";
    });

    final startRes = await widget.controller.submitESignSignature(
      widget.details.id ?? 0,
      _instructionController.text,
      keyword,
    );

    if (_isDisposed) return;

    if (startRes == null ||
        startRes['success'] != true ||
        startRes['transaction_id'] == null) {
      setState(() {
        _isLocalSigning = false;
      });
      return; // snackbar handled by controller
    }

    final txId = startRes['transaction_id'].toString();

    // Start polling loop
    int pollCount = 0;
    const maxPolls = 24; // 2 minutes (24 * 5s)
    bool isSuccess = false;

    while (pollCount < maxPolls && !_isDisposed) {
      if (_isDisposed) break;
      setState(() {
        _localSigningProgressText =
            "Chờ bạn phê duyệt trên app MISA eSign...\nLượt kiểm tra: ${pollCount + 1}/$maxPolls";
      });

      await Future.delayed(const Duration(seconds: 5));
      if (_isDisposed) break;

      final status = await widget.controller.checkESignStatus(txId);
      if (_isDisposed) break;

      if (status == 'SUCCESS') {
        isSuccess = true;
        break;
      } else if (status == 'FAILED' ||
          status == 'REJECTED' ||
          status == 'EXPIRED') {
        break;
      }
      pollCount++;
    }

    if (_isDisposed) return;

    setState(() {
      _isLocalSigning = false;
    });

    if (isSuccess) {
      CustomSnackBar.success(successList: ["Ký eSign thành công!"]);
      widget.onSuccess();
    } else {
      CustomSnackBar.error(
          errorList: ["Quy trình ký eSign không thành công hoặc đã hết hạn"]);
    }
  }
}
