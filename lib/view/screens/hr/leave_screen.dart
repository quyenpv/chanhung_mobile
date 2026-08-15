import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/hr/leave_controller.dart';
import 'package:chanhung/data/model/hr/leave_model.dart';
import 'package:chanhung/data/repo/hr/leave_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_bottom_nav_bar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(LeaveRepo(apiClient: Get.find()));
    final controller = Get.put(LeaveController(leaveRepo: Get.find()));
    controller.isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.leaveApplications.tr),
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppBottomNavBar(current: AppBottomNavItem.hr),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveSheet(context),
        backgroundColor: ColorResources.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(LocalStrings.applyLeave.tr,
            style: regularSmall.copyWith(color: Colors.white)),
      ),
      body: GetBuilder<LeaveController>(
        builder: (controller) {
          if (controller.isLoading) return const CustomLoader();
          return Column(
            children: [
              _FilterBar(controller: controller),
              Expanded(
                child: RefreshIndicator(
                  color: ColorResources.primaryColor,
                  onRefresh: () async => controller.loadLeaves(),
                  child: controller.leavesModel.leaves.isEmpty
                      ? const NoDataWidget(margin: 12)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              Dimensions.space15,
                              Dimensions.space15,
                              Dimensions.space15,
                              90),
                          itemCount: controller.leavesModel.leaves.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Dimensions.space10),
                          itemBuilder: (ctx, i) => _LeaveCard(
                            leave: controller.leavesModel.leaves[i],
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApplyLeaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ApplyLeaveSheet(),
    );
  }
}

// ─── FILTER BAR ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.space15, vertical: Dimensions.space10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(controller.statusFilters.length, (i) {
            final f = controller.statusFilters[i];
            final selected = controller.selectedFilterIndex == i;
            return Padding(
              padding:
                  const EdgeInsetsDirectional.only(end: Dimensions.space10),
              child: ChoiceChip(
                label: Text(f['label'] ?? ''),
                selected: selected,
                onSelected: (_) => controller.setFilter(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── LEAVE CARD ──────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave});
  final LeaveModel leave;

  @override
  Widget build(BuildContext context) {
    final statusColor = _leaveStatusColor(leave.status);
    final controller = Get.find<LeaveController>();
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _LeaveDetailsSheet(leave: leave, controller: controller),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          ColorResources.primaryColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(Dimensions.cardRadius),
                    ),
                    child: const Icon(Icons.event_note,
                        color: ColorResources.primaryColor, size: 20),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.leaveTypeName.isNotEmpty
                              ? leave.leaveTypeName
                              : LocalStrings.leaveApplication.tr,
                          style: mediumLarge.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color),
                        ),
                        Text(
                          leave.applicantName,
                          style: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: leave.status, color: statusColor),
                ],
              ),
              const SizedBox(height: Dimensions.space10),
              const Divider(height: 1),
              const SizedBox(height: Dimensions.space10),
              Wrap(
                spacing: Dimensions.space15,
                runSpacing: Dimensions.space5,
                children: [
                  _Meta(
                      icon: Icons.calendar_today_outlined,
                      label: LocalStrings.leaveStart.tr,
                      value: leave.startDate),
                  _Meta(
                      icon: Icons.calendar_today,
                      label: LocalStrings.leaveEnd.tr,
                      value: leave.endDate),
                  if (leave.duration.isNotEmpty)
                    _Meta(
                        icon: Icons.timelapse,
                        label: LocalStrings.leaveDuration.tr,
                        value: leave.duration),
                ],
              ),
              if (leave.reason.isNotEmpty) ...[
                const SizedBox(height: Dimensions.space10),
                Text(
                  leave.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: regularSmall.copyWith(
                      color: ColorResources.blueGreyColor),
                ),
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _localizedStatus(status),
        style: lightSmall.copyWith(color: color),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: ColorResources.blueGreyColor),
        const SizedBox(width: 4),
        Text('$label: ',
            style: lightSmall.copyWith(color: ColorResources.blueGreyColor)),
        Text(value,
            style: mediumSmall.copyWith(color: ColorResources.primaryColor)),
      ],
    );
  }
}

// ─── APPLY LEAVE BOTTOM SHEET ────────────────────────────────────────────────

class _ApplyLeaveSheet extends StatefulWidget {
  const _ApplyLeaveSheet();

  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  LeaveTypeModel? _selectedType;
  bool _halfDay = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: Dimensions.space20,
        right: Dimensions.space20,
        top: Dimensions.space20,
        bottom: bottom + Dimensions.space20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GetBuilder<LeaveController>(
        builder: (ctrl) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorResources.blueGreyColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space15),
              Text(LocalStrings.applyLeave.tr,
                  style: semiBoldLarge.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color)),
              const SizedBox(height: Dimensions.space15),

              // Leave Type Dropdown
              Text(LocalStrings.leaveType.tr,
                  style: mediumSmall.copyWith(
                      color: ColorResources.blueGreyColor)),
              const SizedBox(height: 6),
              DropdownButtonFormField<LeaveTypeModel>(
                value: _selectedType,
                hint: Text(LocalStrings.selectLeaveType.tr),
                decoration: _inputDecor(context),
                items: ctrl.leaveTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.title),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: Dimensions.space15),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: LocalStrings.leaveStart.tr,
                      value: _startDate,
                      onPick: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: _DateField(
                      label: LocalStrings.leaveEnd.tr,
                      value: _endDate,
                      onPick: (d) => setState(() => _endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space10),

              // Half day toggle
              CheckboxListTile(
                value: _halfDay,
                onChanged: (v) => setState(() => _halfDay = v ?? false),
                title: Text(LocalStrings.halfDay.tr, style: regularSmall),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: ColorResources.primaryColor,
              ),
              const SizedBox(height: Dimensions.space10),

              // Reason
              Text(LocalStrings.leaveReason.tr,
                  style: mediumSmall.copyWith(
                      color: ColorResources.blueGreyColor)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: _inputDecor(context).copyWith(
                  hintText: LocalStrings.enterLeaveReason.tr,
                ),
              ),
              const SizedBox(height: Dimensions.space20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.cardRadius)),
                  ),
                  onPressed: ctrl.isSubmitting ? null : () => _submit(ctrl),
                  child: ctrl.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(LocalStrings.submit.tr,
                          style: mediumLarge.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(LeaveController ctrl) async {
    if (_selectedType == null ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.trim().isEmpty) {
      return;
    }
    final ok = await ctrl.applyLeave(
      leaveTypeId: _selectedType!.id,
      startDate: _dateStr(_startDate!),
      endDate: _dateStr(_endDate!),
      reason: _reasonController.text.trim(),
      halfDay: _halfDay,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  InputDecoration _inputDecor(BuildContext ctx) => InputDecoration(
        filled: true,
        fillColor: Theme.of(ctx).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.value, required this.onPick});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: mediumSmall.copyWith(color: ColorResources.blueGreyColor)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) onPick(d);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.cardRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: ColorResources.blueGreyColor),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value!.day}/${value!.month}/${value!.year}'
                      : 'dd/mm/yyyy',
                  style: regularSmall.copyWith(
                      color: value != null
                          ? Theme.of(context).textTheme.bodyMedium!.color
                          : ColorResources.blueGreyColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

Color _leaveStatusColor(String status) {
  switch (status) {
    case 'approved':
      return ColorResources.greenColor;
    case 'pending':
      return ColorResources.yellowColor;
    case 'rejected':
      return ColorResources.redColor;
    default:
      return ColorResources.blueGreyColor;
  }
}

String _localizedStatus(String s) {
  switch (s) {
    case 'approved':
      return LocalStrings.approved;
    case 'pending':
      return LocalStrings.pending;
    case 'rejected':
      return LocalStrings.rejected;
    default:
      return s;
  }
}

// ─── LEAVE DETAILS BOTTOM SHEET ──────────────────────────────────────────────

class _LeaveDetailsSheet extends StatelessWidget {
  const _LeaveDetailsSheet({required this.leave, required this.controller});
  final LeaveModel leave;
  final LeaveController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorResources.blueGreyColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.space15),
          Text('Chi Tiết Đơn Nghỉ Phép',
              style: semiBoldLarge.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color)),
          const SizedBox(height: Dimensions.space15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nhân viên:', style: lightSmall),
              Text(leave.applicantName, style: regularDefault),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loại nghỉ phép:', style: lightSmall),
              Text(
                  leave.leaveTypeName.isNotEmpty
                      ? leave.leaveTypeName
                      : 'Nghỉ phép',
                  style: regularDefault),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thời gian:', style: lightSmall),
              Text('${leave.startDate} - ${leave.endDate}',
                  style: regularDefault),
            ],
          ),
          if (leave.duration.isNotEmpty) ...[
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Số ngày/giờ:', style: lightSmall),
                Text(leave.duration, style: regularDefault),
              ],
            ),
          ],
          const SizedBox(height: Dimensions.space10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trạng thái:', style: lightSmall),
              Text(_localizedStatus(leave.status),
                  style: regularDefault.copyWith(
                      color: _leaveStatusColor(leave.status))),
            ],
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: Dimensions.space15),
            Text('Lý do:', style: lightSmall),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.space10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.cardRadius),
              ),
              child: Text(leave.reason, style: regularDefault),
            ),
          ],
          if (leave.status == 'pending') ...[
            const SizedBox(height: Dimensions.space25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.cardRadius),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await controller.rejectLeave(leave.id);
                    },
                    child: const Text('Từ Chối',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: Dimensions.space15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.cardRadius),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await controller.approveLeave(leave.id);
                    },
                    child: const Text('Phê Duyệt',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Dimensions.space15),
        ],
      ),
    );
  }
}
