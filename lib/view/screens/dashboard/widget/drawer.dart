import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/app_design.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/url_container.dart';
import 'package:chanhung/data/controller/dashboard/dashboard_controller.dart';
import 'package:chanhung/data/model/dashboard/dashboard_model.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/circle_image_button.dart';
import 'package:chanhung/view/components/dialog/warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key, required this.dashboardModel});

  final DashboardModel dashboardModel;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(280, 330).toDouble(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Get.isRegistered<DashboardController>()
            ? GetBuilder<DashboardController>(
                builder: (controller) => _drawerBody(context, controller),
              )
            : _drawerBody(context, null),
      ),
    );
  }

  Widget _drawerBody(BuildContext context, DashboardController? controller) {
    final model = controller?.dashboardModel ?? dashboardModel;
    final client = model.data?.clientData;
    final groups = _buildGroups(controller);
    return Column(
      children: [
        _ProfileHeader(
          avatar: '${UrlContainer.profileImgUrl}${client?.avatar ?? ''}',
          name: '${client?.firstName ?? ''} ${client?.lastName ?? ''}'.trim(),
          subtitle: client?.jobTitle ?? '',
          onTap: () {
            Navigator.pop(context);
            Get.toNamed(RouteHelper.profileScreen);
          },
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            physics: const BouncingScrollPhysics(),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _MenuGroup(group: group);
            },
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _LogoutButton(
          onTap: () {
            if (controller == null &&
                !Get.isRegistered<DashboardController>()) {
              Navigator.pop(context);
              return;
            }
            const WarningAlertDialog().warningAlertDialog(
              context,
              () {
                Get.back();
                Get.find<DashboardController>().logout();
              },
              title: LocalStrings.logoutTitle.tr,
              subTitle: LocalStrings.logoutSureWarningMSg.tr,
            );
          },
        ),
      ],
    );
  }

  List<_DrawerGroupData> _buildGroups(DashboardController? controller) {
    return [
      _DrawerGroupData('TỔNG QUAN', [
        _DrawerEntry(
          LocalStrings.home.tr,
          Icons.home_rounded,
          RouteHelper.dashboardScreen,
        ),
        if (controller?.isProjectsEnable ?? false)
          _DrawerEntry(
            LocalStrings.projects.tr,
            Icons.grid_view_rounded,
            RouteHelper.projectScreen,
          ),
      ]),
      _DrawerGroupData('CÔNG VIỆC', [
        _DrawerEntry(
          'Công việc của tôi',
          Icons.task_alt_rounded,
          RouteHelper.myTasksScreen,
        ),
        _DrawerEntry(
          'Quản lý giao việc',
          Icons.assignment_ind_rounded,
          RouteHelper.deptDailyWorkScreen,
        ),
        if (controller?.isTicketsEnable ?? false)
          _DrawerEntry(
            LocalStrings.tickets.tr,
            Icons.confirmation_number_rounded,
            RouteHelper.ticketScreen,
          ),
        _DrawerEntry(
          'Team Chat',
          Icons.forum_rounded,
          RouteHelper.teamChatScreen,
        ),
        if (controller?.isHumanResourcesEnable ?? false)
          _DrawerEntry(
            LocalStrings.humanResources.tr,
            Icons.groups_rounded,
            RouteHelper.hrScreen,
          ),
        if (controller?.isDmsOfficeEnable ?? false)
          _DrawerEntry(
            LocalStrings.dmsOffice.tr,
            Icons.folder_copy_rounded,
            RouteHelper.dmsScreen,
          ),
      ]),
      _DrawerGroupData('TÀI CHÍNH & HỒ SƠ', [
        if (controller?.isContractsEnable ?? false)
          _DrawerEntry(
            LocalStrings.contracts.tr,
            Icons.description_rounded,
            RouteHelper.contractScreen,
          ),
        if (controller?.isProposalsEnable ?? false)
          _DrawerEntry(
            LocalStrings.proposals.tr,
            Icons.request_quote_rounded,
            RouteHelper.proposalScreen,
          ),
        if (controller?.isEstimatesEnable ?? false)
          _DrawerEntry(
            LocalStrings.estimates.tr,
            Icons.analytics_rounded,
            RouteHelper.estimateScreen,
          ),
        if (controller?.isInvoicesEnable ?? false)
          _DrawerEntry(
            LocalStrings.invoices.tr,
            Icons.receipt_long_rounded,
            RouteHelper.invoiceScreen,
          ),
        if (controller?.isPaymentsEnable ?? false)
          _DrawerEntry(
            LocalStrings.payments.tr,
            Icons.account_balance_wallet_rounded,
            RouteHelper.paymentScreen,
          ),
        if (controller?.isPaymentRequestsEnable ?? false)
          _DrawerEntry(
            'ĐNTT/ĐNTU & Hoàn ứng',
            Icons.payments_rounded,
            RouteHelper.paymentRequestScreen,
          ),
      ]),
      _DrawerGroupData('HỆ THỐNG', [
        _DrawerEntry(
          LocalStrings.settings.tr,
          Icons.settings_rounded,
          RouteHelper.settingsScreen,
        ),
      ]),
    ].where((group) => group.entries.isNotEmpty).toList();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String avatar;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      padding: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppDesign.mutedInk.withValues(alpha: .15),
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppDesign.accentBlue.withValues(alpha: .1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppDesign.accentBlue.withValues(alpha: .25),
                ),
              ),
              child: CircleImageWidget(
                imagePath: avatar,
                isAsset: false,
                isProfile: true,
                width: 58,
                height: 58,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? LocalStrings.viewProfile.tr : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppDesign.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? LocalStrings.viewProfile.tr : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppDesign.mutedInk,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppDesign.mutedInk,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.group});

  final _DrawerGroupData group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 6),
            child: Text(
              group.title,
              style: const TextStyle(
                color: AppDesign.mutedInk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...group.entries.map((entry) => _MenuItem(entry: entry)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.entry});

  final _DrawerEntry entry;

  @override
  Widget build(BuildContext context) {
    final selected = AppTabNavigation.isCurrent(entry.route);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? AppDesign.accentBlue.withValues(alpha: .11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            if (!selected) AppTabNavigation.open(entry.route);
          },
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  height: selected ? 28 : 0,
                  decoration: const BoxDecoration(
                    color: AppDesign.accentBlue,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  entry.icon,
                  size: 21,
                  color: selected ? AppDesign.accentBlue : AppDesign.mutedInk,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppDesign.ink : AppDesign.mutedInk,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ColorResources.blueGreyColor.withValues(alpha: .65),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: ColorResources.colorRed.withValues(alpha: .08),
        leading: const Icon(Icons.power_settings_new_rounded,
            color: ColorResources.colorRed),
        title: Text(
          LocalStrings.logout.tr,
          style: const TextStyle(
            color: ColorResources.colorRed,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: ColorResources.colorRed, size: 18),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerGroupData {
  const _DrawerGroupData(this.title, this.entries);

  final String title;
  final List<_DrawerEntry> entries;
}

class _DrawerEntry {
  const _DrawerEntry(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
