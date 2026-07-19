import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/model/hr/employee_model.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({super.key, required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final isActive = employee.status?.toLowerCase() == 'active';
    final details = [
      _EmployeeDetail(LocalStrings.employeeId.tr, employee.id),
      _EmployeeDetail(LocalStrings.jobTitle.tr, employee.jobTitle),
      _EmployeeDetail('Email', employee.email),
      _EmployeeDetail(LocalStrings.phone.tr, employee.phone),
      _EmployeeDetail(LocalStrings.workType.tr, employee.workType),
      _EmployeeDetail(LocalStrings.company.tr, employee.companyName),
      _EmployeeDetail(LocalStrings.address.tr, employee.address),
    ].where((detail) => detail.value?.trim().isNotEmpty == true).toList();

    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.employeeDetails.tr),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.space15),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.space20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: ColorResources.primaryColor,
                    child: Text(
                      employee.initials,
                      style: mediumLarge.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.space12),
                  Text(employee.fullName, style: mediumLarge),
                  if (employee.jobTitle?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: Dimensions.space5),
                    Text(
                      employee.jobTitle!,
                      style: regularSmall.copyWith(
                        color: ColorResources.blueGreyColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimensions.space10),
                  _StatusPill(
                    status: isActive
                        ? LocalStrings.active.tr
                        : LocalStrings.inactive.tr,
                    color: isActive
                        ? ColorResources.greenColor
                        : ColorResources.redColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimensions.space15),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.space15),
              child: Column(
                children: details
                    .map((detail) => _DetailRow(detail: detail))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeDetail {
  const _EmployeeDetail(this.label, this.value);

  final String label;
  final String? value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final _EmployeeDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              detail.label,
              style: regularSmall.copyWith(
                color: ColorResources.blueGreyColor,
              ),
            ),
          ),
          Expanded(child: Text(detail.value!, style: regularDefault)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Text(status, style: regularSmall.copyWith(color: color)),
    );
  }
}
