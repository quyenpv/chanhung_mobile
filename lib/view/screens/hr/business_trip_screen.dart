import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/hr/business_trip_controller.dart';
import 'package:chanhung/data/model/hr/business_trip_model.dart';
import 'package:chanhung/data/repo/hr/business_trip_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';

class BusinessTripScreen extends StatefulWidget {
  const BusinessTripScreen({super.key});

  @override
  State<BusinessTripScreen> createState() => _BusinessTripScreenState();
}

class _BusinessTripScreenState extends State<BusinessTripScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(BusinessTripRepo(apiClient: Get.find()));
    final controller =
        Get.put(BusinessTripController(businessTripRepo: Get.find()));
    controller.isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: LocalStrings.businessTrips.tr),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: ColorResources.secondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(LocalStrings.createBusinessTrip.tr,
            style: regularSmall.copyWith(color: Colors.white)),
      ),
      body: GetBuilder<BusinessTripController>(
        builder: (ctrl) {
          if (ctrl.isLoading) return const CustomLoader();
          return Column(
            children: [
              _FilterBar(controller: ctrl),
              Expanded(
                child: RefreshIndicator(
                  color: ColorResources.primaryColor,
                  onRefresh: () => ctrl.loadTrips(),
                  child: ctrl.tripsModel.trips.isEmpty
                      ? const NoDataWidget(margin: 12)
                      : ListView.separated(
                          padding: const EdgeInsets.all(Dimensions.space15),
                          itemCount: ctrl.tripsModel.trips.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Dimensions.space10),
                          itemBuilder: (ctx, i) => _TripCard(
                            trip: ctrl.tripsModel.trips[i],
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

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateTripSheet(),
    );
  }
}

// ─── FILTER BAR ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final BusinessTripController controller;

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
              padding: const EdgeInsetsDirectional.only(end: Dimensions.space10),
              child: ChoiceChip(
                label: Text(f['label'] ?? ''),
                selected: selected,
                selectedColor:
                    ColorResources.secondaryColor.withValues(alpha: 0.15),
                labelStyle: regularSmall.copyWith(
                  color: selected
                      ? ColorResources.secondaryColor
                      : Theme.of(context).textTheme.bodyMedium!.color,
                ),
                onSelected: (_) => controller.setFilter(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── TRIP CARD ───────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final BusinessTripModel trip;

  @override
  Widget build(BuildContext context) {
    final statusColor = _tripStatusColor(trip.status);
    final controller = Get.find<BusinessTripController>();
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _TripDetailsSheet(trip: trip, controller: controller),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.15),
          ),
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
                    color: ColorResources.secondaryColor
                        .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(Dimensions.cardRadius),
                  ),
                  child: const Icon(Icons.airplanemode_active,
                      color: ColorResources.secondaryColor, size: 20),
                ),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mediumLarge.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .color),
                      ),
                      if (trip.destination.isNotEmpty)
                        Text(
                          trip.destination,
                          style: regularSmall.copyWith(
                              color: ColorResources.blueGreyColor),
                        ),
                    ],
                  ),
                ),
                _StatusPill(status: trip.status, color: statusColor),
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
                    label: LocalStrings.tripStart.tr,
                    value: trip.startDate),
                _Meta(
                    icon: Icons.calendar_today,
                    label: LocalStrings.tripEnd.tr,
                    value: trip.endDate),
                if (trip.totalDays != null)
                  _Meta(
                      icon: Icons.nights_stay_outlined,
                      label: LocalStrings.totalDays.tr,
                      value: '${trip.totalDays!.toStringAsFixed(0)} ngày'),
                if (trip.totalAmount != null)
                  _Meta(
                      icon: Icons.monetization_on_outlined,
                      label: LocalStrings.totalAmount.tr,
                      value: trip.totalAmount!.toStringAsFixed(0)),
              ],
            ),
            if (trip.memberName.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: ColorResources.blueGreyColor),
                  const SizedBox(width: 4),
                  Text(trip.memberName,
                      style: regularSmall.copyWith(
                          color: ColorResources.blueGreyColor)),
                ],
              ),
            ],
          ],
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
  const _Meta(
      {required this.icon, required this.label, required this.value});
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
            style: mediumSmall.copyWith(
                color: ColorResources.secondaryColor)),
      ],
    );
  }
}

// ─── CREATE TRIP BOTTOM SHEET ────────────────────────────────────────────────

class _CreateTripSheet extends StatefulWidget {
  const _CreateTripSheet();

  @override
  State<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<_CreateTripSheet> {
  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _purposeCtrl.dispose();
    _notesCtrl.dispose();
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GetBuilder<BusinessTripController>(
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
              Text(LocalStrings.createBusinessTrip.tr,
                  style: semiBoldLarge.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color)),
              const SizedBox(height: Dimensions.space15),

              _Field(
                label: LocalStrings.tripTitle.tr,
                controller: _titleCtrl,
                hint: 'Vd: Công tác Hà Nội Q3/2024',
              ),
              const SizedBox(height: Dimensions.space10),

              _Field(
                label: LocalStrings.destination.tr,
                controller: _destinationCtrl,
                hint: 'Vd: Hà Nội',
              ),
              const SizedBox(height: Dimensions.space10),

              _Field(
                label: LocalStrings.tripPurpose.tr,
                controller: _purposeCtrl,
                hint: 'Mục đích chuyến đi',
                maxLines: 2,
              ),
              const SizedBox(height: Dimensions.space15),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: LocalStrings.tripStart.tr,
                      value: _startDate,
                      onPick: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: _DateField(
                      label: LocalStrings.tripEnd.tr,
                      value: _endDate,
                      onPick: (d) => setState(() => _endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space10),

              _Field(
                label: LocalStrings.tripNotes.tr,
                controller: _notesCtrl,
                hint: 'Ghi chú thêm...',
                maxLines: 2,
              ),
              const SizedBox(height: Dimensions.space20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.secondaryColor,
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
                          style:
                              mediumLarge.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BusinessTripController ctrl) async {
    if (_titleCtrl.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      return;
    }
    final ok = await ctrl.createTrip(
      title: _titleCtrl.text.trim(),
      startDate: _dateStr(_startDate!),
      endDate: _dateStr(_endDate!),
      destination: _destinationCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: mediumSmall.copyWith(
                color: ColorResources.blueGreyColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.cardRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
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
            style: mediumSmall.copyWith(
                color: ColorResources.blueGreyColor)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  BorderRadius.circular(Dimensions.cardRadius),
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
                          ? Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .color
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

Color _tripStatusColor(String status) {
  switch (status) {
    case 'approved':
      return ColorResources.greenColor;
    case 'pending':
      return ColorResources.yellowColor;
    case 'rejected':
    case 'cancelled':
      return ColorResources.redColor;
    case 'draft':
      return ColorResources.blueGreyColor;
    default:
      return ColorResources.blueColor;
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
    case 'draft':
      return 'Nháp';
    case 'cancelled':
      return 'Đã Hủy';
    default:
      return s;
  }
}

// ─── TRIP DETAILS BOTTOM SHEET ──────────────────────────────────────────────

class _TripDetailsSheet extends StatefulWidget {
  const _TripDetailsSheet({required this.trip, required this.controller});
  final BusinessTripModel trip;
  final BusinessTripController controller;

  @override
  State<_TripDetailsSheet> createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<_TripDetailsSheet> {
  bool _loadingDetails = true;
  BusinessTripModel? _fullTrip;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await widget.controller.loadTripDetails(widget.trip.id);
    if (mounted) {
      setState(() {
        _fullTrip = details ?? widget.trip;
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _fullTrip ?? widget.trip;
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
            Text('Chi Tiết Yêu Cầu Công Tác', style: semiBoldLarge.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color)),
            const SizedBox(height: Dimensions.space15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nhân viên:', style: lightSmall),
                Text(trip.memberName, style: regularDefault),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chủ đề:', style: lightSmall),
                Text(trip.title, style: regularDefault),
              ],
            ),
            if (trip.destination.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Điểm đến:', style: lightSmall),
                  Text(trip.destination, style: regularDefault),
                ],
              ),
            ],
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thời gian:', style: lightSmall),
                Text('${trip.startDate} - ${trip.endDate}', style: regularDefault),
              ],
            ),
            if (trip.totalDays != null) ...[
              const SizedBox(height: Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Số ngày:', style: lightSmall),
                  Text('${trip.totalDays!.toStringAsFixed(0)} ngày', style: regularDefault),
                ],
              ),
            ],
            if (trip.totalAmount != null) ...[
              const SizedBox(height: Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng phụ cấp:', style: lightSmall),
                  Text(trip.totalAmount!.toStringAsFixed(0), style: regularDefault),
                ],
              ),
            ],
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trạng thái:', style: lightSmall),
                Text(_localizedStatus(trip.status), 
                  style: regularDefault.copyWith(color: _tripStatusColor(trip.status))),
              ],
            ),
            if (trip.purpose.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space15),
              Text('Mục đích:', style: lightSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.space10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(trip.purpose, style: regularDefault),
              ),
            ],
            if (trip.notes.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space15),
              Text('Ghi chú:', style: lightSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.space10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(trip.notes, style: regularDefault),
              ),
            ],
            if (_loadingDetails) ...[
              const SizedBox(height: Dimensions.space15),
              const Center(child: CircularProgressIndicator()),
            ] else if (trip.expenses != null && trip.expenses!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space15),
              Text('Danh Sách Chi Phí:', style: mediumSmall.copyWith(color: ColorResources.blueGreyColor)),
              const SizedBox(height: Dimensions.space10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trip.expenses!.length,
                separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space5),
                itemBuilder: (ctx, idx) {
                  final exp = trip.expenses![idx];
                  return Container(
                    padding: const EdgeInsets.all(Dimensions.space10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.expenseType, style: regularDefault),
                            Text(exp.expenseDate, style: lightSmall),
                            if (exp.note.isNotEmpty)
                              Text(exp.note, style: lightSmall.copyWith(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        Text(exp.amount != null ? exp.amount!.toStringAsFixed(0) : '0',
                            style: mediumDefault.copyWith(color: ColorResources.secondaryColor)),
                      ],
                    ),
                  );
                },
              ),
            ],
            if (trip.status == 'pending') ...[
              const SizedBox(height: Dimensions.space25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.controller.rejectTrip(trip.id);
                      },
                      child: const Text('Từ Chối', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.controller.approveTrip(trip.id);
                      },
                      child: const Text('Phê Duyệt', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Dimensions.space15),
          ],
        ),
      ),
    );
  }
}
