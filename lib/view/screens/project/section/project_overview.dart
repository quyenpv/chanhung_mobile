import 'package:chanhung/core/helper/string_format_helper.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/project/project_dashboard_model.dart';
import 'package:chanhung/data/model/project/project_details_model.dart';
import 'package:chanhung/view/components/card/custom_card.dart';
import 'package:chanhung/view/components/divider/custom_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({
    super.key,
    required this.project,
    required this.currency,
  });
  final Project project;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final counts = project.counts;
    final tasks = project.taskStats;
    final finance = project.finance;
    final isLate = (project.health ?? '') == LocalStrings.healthLate;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(project.title ?? '', style: mediumLarge),
                ),
                Text(
                  (project.statusTitle ?? project.status ?? '').tr,
                  style: regularSmall.copyWith(
                    color: ColorResources.projectStatusColor(
                        project.statusId ?? '1'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space8),
            Wrap(
              spacing: Dimensions.space8,
              runSpacing: Dimensions.space5,
              children: [
                if ((project.projectCode ?? '').isNotEmpty)
                  _MetaChip(
                      '${LocalStrings.projectCode.tr}: ${project.projectCode}'),
                if ((project.companyName ?? '').isNotEmpty)
                  _MetaChip(
                      '${LocalStrings.companyName.tr}: ${project.companyName}'),
                if ((project.projectTypeTitle ?? '').isNotEmpty)
                  _MetaChip(
                      '${LocalStrings.projectTypeLabel.tr}: ${project.projectTypeTitle}'),
                if ((project.address ?? '').isNotEmpty)
                  _MetaChip(
                      '${LocalStrings.projectLocation.tr}: ${project.address}'),
                _MetaChip(
                    '${LocalStrings.members.tr}: ${project.memberCount ?? '0'}'),
              ],
            ),
            const SizedBox(height: Dimensions.space16),
            CustomCard(
              child: Column(
                children: [
                  _infoRow(LocalStrings.startDate.tr, project.startDate ?? '-',
                      LocalStrings.deadline.tr, project.deadline ?? '-'),
                  const CustomDivider(space: Dimensions.space10),
                  _infoRow(
                    LocalStrings.actualProgress.tr,
                    '${project.progress ?? '0'}%',
                    LocalStrings.healthNormal.tr,
                    isLate
                        ? LocalStrings.healthLate.tr
                        : LocalStrings.healthNormal.tr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            CustomCard(
              child: Column(
                children: [
                  _moneyRow(
                      LocalStrings.projectContractValue.tr, project.price),
                  _moneyRow(LocalStrings.settledAmount.tr,
                      project.totalSettledAmount),
                  _moneyRow(
                      LocalStrings.netPayable.tr, project.totalNetPayable),
                  _moneyRow(LocalStrings.remainingAmount.tr, project.remaining),
                  _moneyRow(LocalStrings.paymentPercent.tr,
                      '${project.paymentProgress ?? '0'}%',
                      raw: true),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            CustomCard(
              child: Column(
                children: [
                  _moneyRow(LocalStrings.budget.tr, project.budget),
                  _moneyRow(LocalStrings.income.tr, finance.investor.actual),
                  _moneyRow(LocalStrings.expense.tr, project.actualCost),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            Wrap(
              spacing: Dimensions.space8,
              runSpacing: Dimensions.space8,
              children: [
                _CountChip(LocalStrings.tasks.tr, tasks.total),
                _CountChip(LocalStrings.projectFiles.tr, counts.files),
                _CountChip(LocalStrings.contracts.tr, counts.contracts),
                _CountChip(LocalStrings.settlements.tr, counts.settlements),
                _CountChip(LocalStrings.invoices.tr, counts.invoices),
                _CountChip('HSE', counts.hse),
                _CountChip('RFI', counts.rfi),
                _CountChip(LocalStrings.comments.tr, counts.comments),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LocalStrings.tasks.tr, style: mediumDefault),
                  const SizedBox(height: Dimensions.space8),
                  _taskRow('Chưa làm', tasks.todo, ColorResources.blueColor),
                  _taskRow('Đang làm', tasks.doing, ColorResources.yellowColor),
                  _taskRow('Hoàn thành', tasks.done, ColorResources.colorGreen),
                  _taskRow(LocalStrings.overdueTasks.tr, tasks.overdue,
                      ColorResources.colorRed),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            _partyBlock(LocalStrings.investor.tr, finance.investor),
            const SizedBox(height: Dimensions.space8),
            _partyBlock(LocalStrings.contractor.tr, finance.contractor),
            const SizedBox(height: Dimensions.space8),
            _partyBlock(LocalStrings.supplier.tr, finance.supplier),
            const SizedBox(height: Dimensions.space10),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalStrings.description.tr,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Divider(
                    color: ColorResources.blueGreyColor,
                    thickness: 0.50,
                  ),
                  Text(
                    project.description ?? '-',
                    style: lightSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String leftLabel, String leftValue, String rightLabel,
      String rightValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel, style: lightSmall),
              Text(leftValue, style: regularDefault),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: lightSmall),
              Text(rightValue, style: regularDefault),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moneyRow(String label, dynamic value, {bool raw = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    regularSmall.copyWith(color: ColorResources.blueGreyColor)),
          ),
          Text(raw ? value.toString() : Converter.formatMoney(value),
              style: regularDefault),
        ],
      ),
    );
  }

  Widget _taskRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.space8),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: Dimensions.space8),
          Expanded(child: Text(label, style: regularSmall)),
          Text('$value', style: mediumDefault),
        ],
      ),
    );
  }

  Widget _partyBlock(String title, PartyAmounts party) {
    return CustomCard(
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space8, vertical: Dimensions.space5),
      decoration: BoxDecoration(
        color: ColorResources.lightBlueGreyColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(text,
          style: regularSmall.copyWith(color: ColorResources.textDarkColor)),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(color: ColorResources.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: mediumLarge.copyWith(color: ColorResources.primaryColor)),
          const SizedBox(height: Dimensions.space5),
          Text(label,
              style:
                  regularSmall.copyWith(color: ColorResources.blueGreyColor)),
        ],
      ),
    );
  }
}
