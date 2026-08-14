import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/route/route.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/hr/hr_controller.dart';
import 'package:chanhung/data/model/hr/employee_model.dart';
import 'package:chanhung/data/model/hr/hr_dashboard_model.dart';
import 'package:chanhung/data/repo/hr/hr_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/hr/employee_details_screen.dart';

class HrScreen extends StatefulWidget {
  const HrScreen({super.key});

  @override
  State<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends State<HrScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(HrRepo(apiClient: Get.find()));
    final controller = Get.put(HrController(hrRepo: Get.find()));
    controller.isLoading = true;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.humanResources.tr),
      drawer: const AppDrawer(),
      body: GetBuilder<HrController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          final employees = controller.visibleEmployees;
          final metrics = controller.hrDashboardModel.metrics;

          return RefreshIndicator(
            color: Theme.of(context).primaryColor,
            onRefresh: () async {
              await controller.initialData(shouldLoad: false);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Dimensions.space15),
              children: [
                // ── HR Quick Actions ─────────────────────────────────
                const _HrQuickActions(),
                const SizedBox(height: Dimensions.space20),

                // ── Search ──────────────────────────────────────────
                _HrSearchField(
                  controller: _searchController,
                  isLoading: controller.isSearching,
                  onChanged: controller.filterEmployees,
                  onSubmitted: controller.searchEmployees,
                  onClear: () async {
                    _searchController.clear();
                    await controller.clearSearch();
                  },
                ),

                if (metrics != null) ...[
                  const SizedBox(height: Dimensions.space15),
                  _HrSummary(
                    metrics: metrics,
                    selectedFilter: controller.selectedFilter,
                    onSelected: controller.selectFilter,
                  ),
                ],
                const SizedBox(height: Dimensions.space20),
                _SectionHeader(
                  title: LocalStrings.employees.tr,
                  count: employees.length.toString(),
                ),
                const SizedBox(height: Dimensions.space10),
                if (employees.isEmpty)
                  const NoDataWidget(margin: 12)
                else
                  ...employees.map((employee) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: Dimensions.space10),
                        child: _EmployeeCard(employee: employee),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── HR QUICK ACTIONS ─────────────────────────────────────────────────────────

class _HrQuickActions extends StatelessWidget {
  const _HrQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.access_time_rounded,
        label: LocalStrings.myAttendance.tr,
        color: ColorResources.primaryColor,
        route: RouteHelper.attendanceScreen,
      ),
      _QuickAction(
        icon: Icons.event_note_rounded,
        label: LocalStrings.myLeaves.tr,
        color: ColorResources.blueColor,
        route: RouteHelper.leaveScreen,
      ),
      _QuickAction(
        icon: Icons.airplanemode_active_rounded,
        label: LocalStrings.myBusinessTrips.tr,
        color: ColorResources.secondaryColor,
        route: RouteHelper.businessTripScreen,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 16, color: ColorResources.primaryColor),
            const SizedBox(width: Dimensions.space5),
            Text(LocalStrings.hrMenu.tr, style: regularLarge),
          ],
        ),
        const SizedBox(height: Dimensions.space10),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: actions.last == a ? 0 : Dimensions.space10,
                      ),
                      child: _QuickActionCard(action: a),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(action.route),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: Dimensions.space15, horizontal: Dimensions.space10),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Dimensions.cardRadius + 2),
          border: Border.all(color: action.color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: Dimensions.space7),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: regularSmall.copyWith(color: action.color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SEARCH FIELD ─────────────────────────────────────────────────────────────

class _HrSearchField extends StatelessWidget {
  const _HrSearchField({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: LocalStrings.search.tr,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─── HR SUMMARY ───────────────────────────────────────────────────────────────

class _HrSummary extends StatelessWidget {
  const _HrSummary({
    required this.metrics,
    required this.selectedFilter,
    required this.onSelected,
  });

  final HrMetrics metrics;
  final HrEmployeeFilter selectedFilter;
  final ValueChanged<HrEmployeeFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        icon: Icons.groups_outlined,
        label: LocalStrings.totalEmployees.tr,
        value: metrics.totalEmployees.toString(),
        color: ColorResources.primaryColor,
        filter: HrEmployeeFilter.all,
      ),
      _SummaryItem(
        icon: Icons.person_add_alt_1_outlined,
        label: LocalStrings.newEmployeesThisMonth.tr,
        value: metrics.newEmployeesThisMonth.toString(),
        color: ColorResources.blueColor,
        filter: HrEmployeeFilter.newThisMonth,
      ),
      _SummaryItem(
        icon: Icons.how_to_reg_outlined,
        label: LocalStrings.presentToday.tr,
        value: metrics.presentToday.toString(),
        color: ColorResources.greenColor,
        filter: HrEmployeeFilter.presentToday,
      ),
      _SummaryItem(
        icon: Icons.event_busy_outlined,
        label: LocalStrings.onLeaveToday.tr,
        value: metrics.onLeaveToday.toString(),
        color: ColorResources.redColor,
        filter: HrEmployeeFilter.onLeaveToday,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        final width =
            (constraints.maxWidth - Dimensions.space10 * (columns - 1)) /
                columns;
        return Wrap(
          spacing: Dimensions.space10,
          runSpacing: Dimensions.space10,
          children: items
              .map((item) => SizedBox(
                    width: width,
                    height: 86,
                    child: _SummaryItemCard(
                      item: item,
                      isSelected: selectedFilter == item.filter,
                      onTap: () => onSelected(item.filter),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.filter,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final HrEmployeeFilter filter;
}

class _SummaryItemCard extends StatelessWidget {
  const _SummaryItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _SummaryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.label}: ${item.value}',
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(Dimensions.space10),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.cardRadius),
            border: Border.all(
              color: item.color.withValues(alpha: isSelected ? 0.70 : 0.18),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.value,
                        style: mediumLarge.copyWith(color: item.color)),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regularSmall.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: ColorResources.secondaryColor,
        ),
        const SizedBox(width: Dimensions.space5),
        Text(title, style: regularLarge),
        const Spacer(),
        Text(
          count,
          style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      onTap: () => Get.to(() => EmployeeDetailsScreen(employee: employee)),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ColorResources.primaryColor,
                child: Text(
                  employee.initials,
                  style: mediumLarge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mediumLarge.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space5),
                    Text(
                      employee.jobTitle?.isNotEmpty == true
                          ? employee.jobTitle!
                          : employee.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regularSmall.copyWith(
                        color: ColorResources.blueGreyColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space5),
                    Wrap(
                      spacing: Dimensions.space10,
                      runSpacing: Dimensions.space5,
                      children: [
                        if (employee.email?.isNotEmpty == true)
                          _InfoChip(
                              icon: Icons.mail_outline, text: employee.email!),
                        if (employee.phone?.isNotEmpty == true)
                          _InfoChip(
                              icon: Icons.phone_outlined,
                              text: employee.phone!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              _StatusPill(status: employee.status ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorResources.blueGreyColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.42,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: lightSmall.copyWith(color: ColorResources.blueGreyColor),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    final color =
        isActive ? ColorResources.greenColor : ColorResources.redColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(
        isActive ? LocalStrings.active.tr : LocalStrings.inactive.tr,
        style: lightSmall.copyWith(color: color),
      ),
    );
  }
}
