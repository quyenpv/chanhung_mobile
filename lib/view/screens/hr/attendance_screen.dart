import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/hr/attendance_controller.dart';
import 'package:chanhung/data/model/hr/attendance_model.dart';
import 'package:chanhung/data/repo/hr/attendance_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(AttendanceRepo(apiClient: Get.find()));
    final controller =
        Get.put(AttendanceController(attendanceRepo: Get.find()));
    controller.isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.attendance.tr),
      drawer: const AppDrawer(),
      body: GetBuilder<AttendanceController>(
        builder: (ctrl) {
          if (ctrl.isLoading) return const CustomLoader();
          return RefreshIndicator(
            color: ColorResources.primaryColor,
            onRefresh: () => ctrl.initialData(shouldLoad: false),
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.space15),
              children: [
                _CheckInCard(controller: ctrl),
                const SizedBox(height: Dimensions.space20),
                _HistorySection(controller: ctrl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── CHECK-IN CARD ───────────────────────────────────────────────────────────

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.todayStatus;
    final checkedIn = status?.checkedInToday ?? false;
    final checkedOut = status?.checkedOutToday ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorResources.primaryColor,
            ColorResources.primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius + 4),
        boxShadow: [
          BoxShadow(
            color: ColorResources.primaryColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(LocalStrings.attendance.tr,
                  style: mediumLarge.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: Dimensions.space15),
          if (checkedIn) ...[
            _TimeRow(
              icon: Icons.login,
              label: LocalStrings.checkInTime.tr,
              value: status?.checkInTime ?? '-',
            ),
            if (checkedOut)
              _TimeRow(
                icon: Icons.logout,
                label: LocalStrings.checkOutTime.tr,
                value: status?.checkOutTime ?? '-',
              ),
            if (checkedOut && (status?.totalHours?.isNotEmpty ?? false))
              _TimeRow(
                icon: Icons.timelapse,
                label: LocalStrings.workingHours.tr,
                value: '${status!.totalHours} h',
              ),
          ] else ...[
            Text(
              LocalStrings.notCheckedIn.tr,
              style: regularDefault.copyWith(
                  color: Colors.white.withValues(alpha: 0.80)),
            ),
          ],
          const SizedBox(height: Dimensions.space20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: LocalStrings.checkIn.tr,
                  icon: Icons.login,
                  enabled: !checkedIn && !controller.isChecking,
                  color: Colors.white,
                  textColor: ColorResources.primaryColor,
                  onTap: () => controller.doCheckIn(),
                ),
              ),
              if (checkedIn && !checkedOut) ...[
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: _ActionButton(
                    label: LocalStrings.checkOut.tr,
                    icon: Icons.logout,
                    enabled: !controller.isChecking,
                    color: Colors.white.withValues(alpha: 0.2),
                    textColor: Colors.white,
                    onTap: () => controller.doCheckOut(),
                  ),
                ),
              ],
            ],
          ),
          if (controller.isChecking)
            const Padding(
              padding: EdgeInsets.only(top: Dimensions.space10),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.70)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: regularSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.70))),
          Text(value,
              style: mediumSmall.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.color,
    required this.textColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool enabled;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(Dimensions.cardRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
              Text(label,
                  style: mediumSmall.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HISTORY SECTION ─────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.controller});
  final AttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 3,
                height: 16,
                color: ColorResources.secondaryColor),
            const SizedBox(width: Dimensions.space5),
            Text(LocalStrings.attendanceHistory.tr,
                style: regularLarge),
          ],
        ),
        const SizedBox(height: Dimensions.space10),
        if (controller.isHistoryLoading)
          const CustomLoader()
        else if (controller.historyModel.records.isEmpty)
          const NoDataWidget(margin: 12)
        else
          ...controller.historyModel.records
              .map((r) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: Dimensions.space10),
                    child: _AttendanceRow(record: r),
                  )),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _attendanceStatusColor(record.status);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.space15, vertical: Dimensions.space12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.today, color: statusColor, size: 20),
            ),
            const SizedBox(width: Dimensions.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.date,
                      style: mediumSmall.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .color)),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (record.checkIn != null)
                        _InfoChip(
                            icon: Icons.login,
                            text: record.checkIn!),
                      if (record.checkOut != null)
                        _InfoChip(
                            icon: Icons.logout,
                            text: record.checkOut!),
                      if (record.totalHours != null)
                        _InfoChip(
                            icon: Icons.timelapse,
                            text: '${record.totalHours} h'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.status,
                style: lightSmall.copyWith(color: statusColor),
              ),
            ),
          ],
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
        Icon(icon, size: 13, color: ColorResources.blueGreyColor),
        const SizedBox(width: 3),
        Text(text,
            style: lightSmall.copyWith(
                color: ColorResources.blueGreyColor)),
      ],
    );
  }
}

Color _attendanceStatusColor(String s) {
  switch (s) {
    case 'present':
      return ColorResources.greenColor;
    case 'absent':
      return ColorResources.redColor;
    case 'half_day':
      return ColorResources.yellowColor;
    default:
      return ColorResources.blueGreyColor;
  }
}
