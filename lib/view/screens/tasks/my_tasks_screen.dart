import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/local_strings.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/tasks/tasks_controller.dart';
import 'package:chanhung/data/model/project/tasks_model.dart';
import 'package:chanhung/data/repo/tasks/tasks_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/app_drawer.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'package:chanhung/view/components/divider/custom_divider.dart';
import 'package:nb_utils/nb_utils.dart' hide NoDataWidget;

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(TasksRepo(apiClient: Get.find()));
    final controller = Get.put(TasksController(tasksRepo: Get.find()));
    controller.isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Công Việc Của Tôi',
      ),
      drawer: const AppDrawer(),
      body: GetBuilder<TasksController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          return Column(
            children: [
              // Filter Bar
              _FilterBar(controller: controller),

              // Tasks List
              Expanded(
                child: RefreshIndicator(
                  color: ColorResources.primaryColor,
                  onRefresh: () => controller.loadMyTasks(),
                  child: controller.tasksList.isEmpty
                      ? const NoDataWidget(margin: 12)
                      : ListView.separated(
                          padding: const EdgeInsets.all(Dimensions.space15),
                          itemCount: controller.tasksList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space10),
                          itemBuilder: (ctx, idx) {
                            final task = controller.tasksList[idx];
                            return _TaskCard(task: task, controller: controller);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15, vertical: Dimensions.space10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(controller.statusFilters.length, (i) {
            final filter = controller.statusFilters[i];
            final isSelected = controller.selectedFilterIndex == i;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: Dimensions.space10),
              child: ChoiceChip(
                label: Text(filter['label'] ?? ''),
                selected: isSelected,
                selectedColor: ColorResources.secondaryColor.withValues(alpha: 0.15),
                labelStyle: regularSmall.copyWith(
                  color: isSelected
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.controller});
  final Task task;
  final TasksController controller;

  @override
  Widget build(BuildContext context) {
    final statusColor = ColorResources.taskStatusColor(task.statusId ?? '1');
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _TaskDetailsSheet(task: task, controller: controller),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  width: 5.0,
                  color: statusColor,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.space15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title ?? '',
                          style: mediumLarge.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge!.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.statusTitle?.capitalize?.tr ?? '',
                          style: lightSmall.copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.space5),
                  if (task.projectTitle != null && task.projectTitle!.isNotEmpty) ...[
                    Text(
                      task.projectTitle!,
                      style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.space5),
                  ],
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: lightSmall.copyWith(color: ColorResources.contentTextColor),
                    ),
                    const SizedBox(height: Dimensions.space10),
                  ],
                  const CustomDivider(space: Dimensions.space5),
                  const SizedBox(height: Dimensions.space5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 14, color: ColorResources.blueGreyColor),
                          const SizedBox(width: 4),
                          Text(
                            task.deadline ?? '-',
                            style: regularSmall.copyWith(color: ColorResources.blueGreyColor),
                          ),
                        ],
                      ),
                      if (task.priorityTitle != null && task.priorityTitle!.isNotEmpty)
                        Text(
                          task.priorityTitle!,
                          style: regularSmall.copyWith(
                              color: ColorResources.taskPriorityColor(task.priorityId ?? '1')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDetailsSheet extends StatefulWidget {
  const _TaskDetailsSheet({required this.task, required this.controller});
  final Task task;
  final TasksController controller;

  @override
  State<_TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<_TaskDetailsSheet> {
  late String _currentStatusId;

  @override
  void initState() {
    super.initState();
    _currentStatusId = widget.task.statusId ?? '1';
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Chi Tiết Công Việc', style: semiBoldLarge.copyWith(
                color: Theme.of(context).textTheme.bodyLarge!.color)),
            const SizedBox(height: Dimensions.space15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tiêu đề:', style: lightSmall),
                Expanded(
                  child: Text(
                    widget.task.title ?? '',
                    style: regularDefault,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            if (widget.task.projectTitle != null && widget.task.projectTitle!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dự án:', style: lightSmall),
                  Expanded(
                    child: Text(
                      widget.task.projectTitle!,
                      style: regularDefault,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hạn chót:', style: lightSmall),
                Text(widget.task.deadline ?? '-', style: regularDefault),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Độ ưu tiên:', style: lightSmall),
                Text(
                  widget.task.priorityTitle ?? '-',
                  style: regularDefault.copyWith(
                      color: ColorResources.taskPriorityColor(widget.task.priorityId ?? '1')),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trạng thái hiện tại:', style: lightSmall),
                Text(
                  widget.task.statusTitle?.capitalize?.tr ?? '',
                  style: regularDefault.copyWith(
                      color: ColorResources.taskStatusColor(_currentStatusId)),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space15),
            if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
              Text('Mô tả:', style: lightSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.space10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(widget.task.description!, style: regularDefault),
              ),
              const SizedBox(height: Dimensions.space20),
            ],
            const Divider(),
            const SizedBox(height: Dimensions.space10),
            Text('Chuyển Trạng Thái:', style: mediumSmall.copyWith(color: ColorResources.blueGreyColor)),
            const SizedBox(height: Dimensions.space10),
            Row(
              children: [
                _StatusButton(
                  label: 'To Do',
                  isSelected: _currentStatusId == '1',
                  color: ColorResources.taskStatusColor('1'),
                  onTap: () => _updateStatus('1'),
                ),
                const SizedBox(width: Dimensions.space10),
                _StatusButton(
                  label: 'In Progress',
                  isSelected: _currentStatusId == '2',
                  color: ColorResources.taskStatusColor('2'),
                  onTap: () => _updateStatus('2'),
                ),
                const SizedBox(width: Dimensions.space10),
                _StatusButton(
                  label: 'Done',
                  isSelected: _currentStatusId == '3',
                  color: ColorResources.taskStatusColor('3'),
                  onTap: () => _updateStatus('3'),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String statusId) async {
    if (statusId == _currentStatusId) return;
    Navigator.pop(context);
    final ok = await widget.controller.updateStatus(widget.task.id ?? '', int.parse(statusId));
    if (ok) {
      setState(() {
        _currentStatusId = statusId;
      });
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.cardRadius),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: mediumSmall.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
