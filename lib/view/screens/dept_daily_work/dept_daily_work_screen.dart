import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';

import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/dept_daily_work/dept_daily_work_controller.dart';
import 'package:chanhung/data/repo/dept_daily_work/dept_daily_work_repo.dart';
import 'package:chanhung/data/services/api_service.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/custom_loader/custom_loader.dart';
import 'package:chanhung/view/components/no_data.dart';
import 'dept_daily_work_detail_screen.dart';

class DeptDailyWorkScreen extends StatefulWidget {
  const DeptDailyWorkScreen({super.key});

  @override
  State<DeptDailyWorkScreen> createState() => _DeptDailyWorkScreenState();
}

class _DeptDailyWorkScreenState extends State<DeptDailyWorkScreen> {
  @override
  void initState() {
    Get.put(ApiClient(sharedPreferences: Get.find()));
    Get.put(DeptDailyWorkRepo(apiClient: Get.find()));
    Get.put(DeptDailyWorkController(deptDailyWorkRepo: Get.find()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeptDailyWorkController>(
      builder: (controller) => Scaffold(
        backgroundColor: ColorResources.getScreenBgColor(),
        appBar: CustomAppBar(
          title: 'Quản lý giao việc',
          isShowBackBtn: true,
          actionWidget: controller.departmentList.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(right: Dimensions.space15),
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space10),
                  decoration: BoxDecoration(
                    color: ColorResources.colorWhite,
                    borderRadius:
                        BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: DropdownButton<String>(
                    value: controller.selectedDepartmentId,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.changeDepartment(newValue);
                      }
                    },
                    items: controller.departmentList
                        .map<DropdownMenuItem<String>>((model) {
                      return DropdownMenuItem<String>(
                        value: model.id,
                        child: Text(
                          model.name ?? '',
                          style: regularDefault.copyWith(
                              color: ColorResources.colorBlack),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: controller.isLoading
            ? const CustomLoader()
            : controller.taskList.isEmpty
                ? const NoDataWidget(margin: 12)
                : RefreshIndicator(
                    onRefresh: () async {
                      await controller.loadTasks();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(Dimensions.space15),
                      itemCount: controller.taskList.length,
                      itemBuilder: (context, index) {
                        final task = controller.taskList[index];
                        return GestureDetector(
                          onTap: () {
                            Get.to(() => DeptDailyWorkDetailScreen(task: task))
                                ?.then((value) {
                              if (value == true) {
                                controller.loadTasks();
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: Dimensions.space15),
                            padding: const EdgeInsets.all(Dimensions.space15),
                            decoration: BoxDecoration(
                              color: ColorResources.colorWhite,
                              borderRadius: BorderRadius.circular(
                                  Dimensions.defaultRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorResources.colorBlack.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title ?? '',
                                        style: semiBoldDefault.copyWith(
                                            fontSize: Dimensions.fontLarge),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          task.status,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getStatusText(task.status),
                                        style: regularSmall.copyWith(
                                            color:
                                                _getStatusColor(task.status)),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: Dimensions.space10),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 16,
                                        color: ColorResources.colorGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task.assigneeNames ?? 'Chưa giao',
                                        style: regularSmall.copyWith(
                                            color: ColorResources.colorGrey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.space10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Tiến độ',
                                            style: regularSmall.copyWith(
                                                color:
                                                    ColorResources.colorGrey)),
                                        Text('${task.progressPercent ?? 0}%',
                                            style: semiBoldSmall),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: (task.progressPercent ?? 0) / 100,
                                      backgroundColor: ColorResources.colorGrey
                                          .withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _getProgressBarColor(
                                              task.progressPercent ?? 0)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Dimensions.space10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Hạn: ${task.deadline ?? "-"}',
                                        style: regularSmall.copyWith(
                                            color: ColorResources.colorGrey)),
                                    if (task.priority != null)
                                      Text(
                                        _getPriorityText(task.priority),
                                        style: regularSmall.copyWith(
                                            color: _getPriorityColor(
                                                task.priority)),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'open':
        return 'Chưa làm';
      case 'in_progress':
        return 'Đang làm';
      case 'done':
        return 'Đã xong';
      default:
        return 'Chưa làm';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return ColorResources.colorGrey;
      case 'in_progress':
        return ColorResources.colorOrange;
      case 'done':
        return ColorResources.colorGreen;
      default:
        return ColorResources.colorGrey;
    }
  }

  Color _getProgressBarColor(int percent) {
    if (percent >= 100) return ColorResources.colorGreen;
    if (percent >= 70) return ColorResources.primaryColor;
    if (percent > 0) return ColorResources.colorOrange;
    return ColorResources.colorGrey;
  }

  String _getPriorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'normal':
        return 'Bình thường';
      case 'low':
        return 'Thấp';
      default:
        return 'Bình thường';
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return ColorResources.colorRed;
      case 'normal':
        return ColorResources.colorGrey;
      case 'low':
        return ColorResources.colorGrey;
      default:
        return ColorResources.colorGrey;
    }
  }
}
