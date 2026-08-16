import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/helper/string_format_helper.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/project/project_controller.dart';
import 'package:chanhung/data/model/project/project_dashboard_model.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/screens/project/widget/project_card.dart';
import 'package:chanhung/view/screens/project/widget/project_metric_tile.dart';

class ProjectDashboardSection extends StatelessWidget {
  const ProjectDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectController>(
      builder: (controller) {
        if (controller.isDashboardLoading) {
          return const CustomLoader();
        }
        final data = controller.dashboardModel.data;
        if (data == null) {
          return const Center(child: NoDataWidget());
        }
        final action = data.actionCenter ?? ActionCenter();
        final finance = data.partyFinance ?? PartyFinance();

        return RefreshIndicator(
          color: ColorResources.primaryColor,
          onRefresh: () async {
            await controller.initialData(shouldLoad: false);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.space16,
              Dimensions.space16,
              Dimensions.space16,
              90,
            ),
            children: [
              Wrap(
                spacing: Dimensions.space8,
                runSpacing: Dimensions.space8,
                children: [
                  ProjectMetricTile(
                    label: LocalStrings.totalProjects.tr,
                    value: '${data.total}',
                    color: ColorResources.primaryColor,
                  ),
                  ProjectMetricTile(
                    label: LocalStrings.overdueProjects.tr,
                    value: '${data.overdue}',
                    color: ColorResources.colorRed,
                  ),
                  ProjectMetricTile(
                    label: LocalStrings.paymentPercent.tr,
                    value: '${data.paymentProgress.round()}%',
                    color: ColorResources.colorGreen,
                  ),
                  ProjectMetricTile(
                    label: LocalStrings.projectContractValue.tr,
                    value: Converter.formatMoney(data.totalPrice),
                  ),
                  ProjectMetricTile(
                    label: LocalStrings.settledAmount.tr,
                    value: Converter.formatMoney(data.totalSettled),
                  ),
                  ProjectMetricTile(
                    label: LocalStrings.remainingAmount.tr,
                    value: Converter.formatMoney(data.totalRemaining),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space16),
              _StatusRow(data: data),
              const SizedBox(height: Dimensions.space16),
              Text(LocalStrings.needAction.tr, style: mediumLarge),
              const SizedBox(height: Dimensions.space8),
              _ActionTile(
                  label: LocalStrings.todayTasks.tr, value: action.todayTasks),
              _ActionTile(
                  label: LocalStrings.overdueTasks.tr,
                  value: action.overdueTasks,
                  danger: true),
              _ActionTile(
                  label: LocalStrings.upcomingTasks.tr,
                  value: action.upcomingTasks),
              _ActionTile(
                  label: LocalStrings.pendingSettlements.tr,
                  value: action.pendingSettlements),
              _ActionTile(
                  label: LocalStrings.openHse.tr, value: action.openHse),
              _ActionTile(
                  label: LocalStrings.openRfi.tr, value: action.openRfi),
              const SizedBox(height: Dimensions.space16),
              _PartyCard(
                  title: LocalStrings.investor.tr, party: finance.investor),
              const SizedBox(height: Dimensions.space8),
              _PartyCard(
                  title: LocalStrings.contractor.tr, party: finance.contractor),
              const SizedBox(height: Dimensions.space8),
              _PartyCard(
                  title: LocalStrings.supplier.tr, party: finance.supplier),
              const SizedBox(height: Dimensions.space16),
              if (data.recentProjects.isNotEmpty) ...[
                Text(LocalStrings.projects.tr, style: mediumLarge),
                const SizedBox(height: Dimensions.space8),
                ...data.recentProjects.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.space10),
                    child: ProjectCard(
                      projectModel: entry.value,
                      animationOrder: entry.key.clamp(0, 5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.data});
  final ProjectDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatusCount(label: LocalStrings.openProjects.tr, value: data.open),
          _StatusCount(label: LocalStrings.holdProjects.tr, value: data.hold),
          _StatusCount(
              label: LocalStrings.completedProjects.tr, value: data.completed),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: mediumLarge),
        const SizedBox(height: Dimensions.space5),
        Text(label,
            style: regularSmall.copyWith(color: ColorResources.blueGreyColor)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.value,
    this.danger = false,
  });
  final String label;
  final int value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space8),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space16, vertical: Dimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: regularDefault)),
          Text(
            '$value',
            style: mediumLarge.copyWith(
              color: danger
                  ? ColorResources.colorRed
                  : ColorResources.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.title, required this.party});
  final String title;
  final PartyAmounts party;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: mediumDefault),
          const SizedBox(height: Dimensions.space8),
          _moneyRow(LocalStrings.contracts.tr, party.contract),
          _moneyRow(LocalStrings.netPayable.tr, party.requested),
          _moneyRow(LocalStrings.income.tr, party.actual),
          _moneyRow(LocalStrings.remainingAmount.tr, party.debt),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.space8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor)),
          ),
          Text(Converter.formatMoney(value), style: regularDefault),
        ],
      ),
    );
  }
}
