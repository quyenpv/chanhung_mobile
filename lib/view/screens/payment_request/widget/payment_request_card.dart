import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/payment_request/payment_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PaymentRequestCard extends StatelessWidget {
  final PaymentRequestModel item;
  final String currency;

  const PaymentRequestCard({
    super.key,
    required this.item,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: currency);
    final formattedAmount = currencyFormatter.format(item.totalAmount ?? 0.0);

    return InkWell(
      onTap: () {
        Get.toNamed(RouteHelper.paymentRequestDetailsScreen, arguments: item.id);
      },
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorResources.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.requestCode ?? 'N/A',
                    style: semiBoldDefault.copyWith(color: ColorResources.primaryColor),
                  ),
                ),
                _buildStatusPill(item.status ?? ''),
              ],
            ),
            const SizedBox(height: Dimensions.space12),
            Text(
              item.title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: boldDefault.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: Dimensions.space10),
            const Divider(height: 1, color: ColorResources.borderColor),
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Người đề nghị",
                      style: regularSmall.copyWith(color: ColorResources.contentTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.requesterName ?? '',
                      style: mediumDefault.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Tổng tiền",
                      style: regularSmall.copyWith(color: ColorResources.contentTextColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedAmount,
                      style: boldDefault.copyWith(color: ColorResources.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.requestDate ?? '',
                  style: regularSmall.copyWith(color: ColorResources.contentTextColor),
                ),
                if (item.prWaitingSignerName != null && item.prWaitingSignerName!.isNotEmpty)
                  Text(
                    "Chờ ký: ${item.prWaitingSignerName}",
                    style: regularSmall.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'draft':
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
        text = 'Nháp';
        break;
      case 'signing':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        text = 'Chờ ký';
        break;
      case 'completed':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        text = 'Đã duyệt';
        break;
      case 'paid':
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green;
        text = 'Đã chi';
        break;
      case 'rejected':
        bgColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red;
        text = 'Từ chối';
        break;
      case 'more_info_required':
        bgColor = Colors.deepOrange.withValues(alpha: 0.15);
        textColor = Colors.deepOrange;
        text = 'Cần bổ sung';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: regularSmall.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
