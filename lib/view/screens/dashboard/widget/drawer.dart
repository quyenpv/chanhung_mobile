import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/data/model/dashboard/dashboard_model.dart';
import 'package:chanhung/view/components/circle_image_button.dart';
import 'package:chanhung/view/components/dialog/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/style.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key, required this.dashboardModel});
  final DashboardModel dashboardModel;

  @override
  Widget build(BuildContext context) {
    final clientData = dashboardModel.data?.clientData;

    return Drawer(
      child: SafeArea(
        child: GetBuilder<DashboardController>(builder: (controller) {
          return ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: ColorResources.blueGreyColor,
                      radius: 36,
                      child: CircleImageWidget(
                        imagePath:
                            '${UrlContainer.profileImgUrl}${clientData?.avatar ?? ''}',
                        isAsset: false,
                        isProfile: true,
                        width: 70,
                        height: 70,
                      ),
                    ),
                    const SizedBox(width: Dimensions.space15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dashboardModel.data?.clientData?.firstName ?? ''} ${dashboardModel.data?.clientData?.lastName ?? ''}',
                            style: semiBoldLarge.copyWith(
                                color:
                                    Theme.of(context).textTheme.bodyLarge!.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              if (dashboardModel.data != null) {
                                Get.toNamed(RouteHelper.profileScreen);
                              }
                            },
                            child: Text(
                              LocalStrings.viewProfile.tr,
                              style: mediumDefault.copyWith(
                                  color: Theme.of(context).secondaryHeaderColor,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (controller.isProjectsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.task_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.projects.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.projectScreen);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: ColorResources.primaryColor,
                ),
                title: Text(
                  'Công Việc Của Tôi',
                  style: regularDefault.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: Dimensions.space12,
                  color: ColorResources.contentTextColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RouteHelper.myTasksScreen);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.assignment_ind_outlined,
                  color: ColorResources.primaryColor,
                ),
                title: Text(
                  'Quản lý giao việc',
                  style: regularDefault.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: Dimensions.space12,
                  color: ColorResources.contentTextColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RouteHelper.deptDailyWorkScreen);
                },
              ),
              if (controller.isContractsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.article_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.contracts.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.contractScreen);
                  },
                ),
              if (controller.isProposalsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.document_scanner_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.proposals.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.proposalScreen);
                  },
                ),
              if (controller.isEstimatesEnable)
                ListTile(
                  leading: const Icon(
                    Icons.add_chart_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.estimates.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.estimateScreen);
                  },
                ),
              if (controller.isInvoicesEnable)
                ListTile(
                  leading: const Icon(
                    Icons.assignment_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.invoices.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.invoiceScreen);
                  },
                ),
              if (controller.isPaymentsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.money,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.payments.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.paymentScreen);
                  },
                ),
              if (controller.isPaymentRequestsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    "ĐNTT/ĐNTU & Hoàn ứng",
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.paymentRequestScreen);
                  },
                ),
              if (controller.isTicketsEnable)
                ListTile(
                  leading: const Icon(
                    Icons.confirmation_number_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.tickets.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.ticketScreen);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: ColorResources.primaryColor,
                ),
                title: Text(
                  'Team Chat',
                  style: regularDefault.copyWith(
                      color:
                          Theme.of(context).textTheme.bodyMedium!.color),
                ),
                subtitle: Text(
                  'Chat nội bộ ERP',
                  style: regularSmall.copyWith(color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: Dimensions.space12,
                  color: ColorResources.contentTextColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RouteHelper.teamChatScreen);
                },
              ),
              if (controller.isHumanResourcesEnable)
                ListTile(
                  leading: const Icon(
                    Icons.groups_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.humanResources.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.hrScreen);
                  },
                ),
              if (controller.isDmsOfficeEnable)
                ListTile(
                  leading: const Icon(
                    Icons.folder_copy_outlined,
                    color: ColorResources.primaryColor,
                  ),
                  title: Text(
                    LocalStrings.dmsOffice.tr,
                    style: regularDefault.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: Dimensions.space12,
                    color: ColorResources.contentTextColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RouteHelper.dmsScreen);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.account_circle_outlined,
                  color: ColorResources.primaryColor,
                ),
                title: Text(
                  LocalStrings.settings.tr,
                  style: regularDefault.copyWith(
                      color:
                          Theme.of(context).textTheme.bodyMedium!.color),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: Dimensions.space12,
                  color: ColorResources.contentTextColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RouteHelper.settingsScreen);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  size: Dimensions.space20,
                  color: Colors.red,
                ),
                title: Text(
                  LocalStrings.logout.tr,
                  style: regularDefault.copyWith(
                      color:
                          Theme.of(context).textTheme.bodyMedium!.color),
                ),
                onTap: () {
                  const WarningAlertDialog().warningAlertDialog(context,
                      () {
                    Get.back();
                    Get.find<DashboardController>().logout();
                  },
                      title: LocalStrings.logoutTitle.tr,
                      subTitle: LocalStrings.logoutSureWarningMSg.tr);
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}
