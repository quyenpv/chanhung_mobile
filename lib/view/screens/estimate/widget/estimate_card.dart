import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/estimate/estimate_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:chanhung/view/components/divider/custom_divider.dart';

class EstimateCard extends StatelessWidget {
  const EstimateCard({
    super.key,
    required this.estimateModel,
    required this.currency,
  });
  final Estimate estimateModel;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(RouteHelper.withId(
            RouteHelper.estimateDetailsScreen, estimateModel.id));
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  width: 5.0,
                  color:
                      ColorResources.estimateStatusColor(estimateModel.status!),
                ),
              ),
            ),
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${LocalStrings.estimate.tr} #${estimateModel.id}',
                          style: regularLarge,
                        ),
                        Text(
                          '$currency${estimateModel.estimateValue ?? ''}',
                          style: regularLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.space5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          estimateModel.note ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                        Text(
                          estimateModel.status?.tr.capitalize ?? '',
                          style: regularSmall.copyWith(
                              color: ColorResources.estimateStatusColor(
                                  estimateModel.status ?? '')),
                        ),
                      ],
                    ),
                    const CustomDivider(space: Dimensions.space10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextIcon(
                          text: estimateModel.companyName ?? '',
                          prefix: const Icon(
                            Icons.account_box_rounded,
                            color: ColorResources.primaryColor,
                            size: 16,
                          ),
                          edgeInsets: EdgeInsets.zero,
                          textStyle: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                        TextIcon(
                          text: estimateModel.estimateDate,
                          prefix: const Icon(
                            Icons.calendar_month,
                            color: ColorResources.primaryColor,
                            size: 16,
                          ),
                          edgeInsets: EdgeInsets.zero,
                          textStyle: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                      ],
                    )
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
