import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/style.dart';
import 'package:chanhung/data/controller/dept_daily_work/dept_daily_work_controller.dart';
import 'package:chanhung/data/model/dept_daily_work/dept_daily_work_model.dart';
import 'package:chanhung/view/components/app-bar/custom_appbar.dart';
import 'package:chanhung/view/components/buttons/rounded_button.dart';
import 'package:chanhung/view/components/buttons/rounded_loading_button.dart';

class DeptDailyWorkDetailScreen extends StatefulWidget {
  final DeptDailyWorkModel task;
  const DeptDailyWorkDetailScreen({super.key, required this.task});

  @override
  State<DeptDailyWorkDetailScreen> createState() => _DeptDailyWorkDetailScreenState();
}

class _DeptDailyWorkDetailScreenState extends State<DeptDailyWorkDetailScreen> {
  double _progressValue = 0;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _progressValue = (widget.task.progressPercent ?? 0).toDouble();
    _status = widget.task.status ?? 'open';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResources.getScreenBgColor(),
      appBar: CustomAppBar(
        title: 'Chi tiết công việc',
        isShowBackBtn: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.space15),
              decoration: BoxDecoration(
                color: ColorResources.colorWhite,
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                boxShadow: [
                  BoxShadow(
                    color: ColorResources.colorBlack.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title ?? '',
                    style: semiBoldDefault.copyWith(fontSize: Dimensions.fontLarge),
                  ),
                  const SizedBox(height: Dimensions.space15),
                  _buildInfoRow('Người được giao', widget.task.assigneeNames ?? 'Chưa giao'),
                  _buildInfoRow('Nhóm công việc', widget.task.listTitle ?? '-'),
                  _buildInfoRow('Ngày bắt đầu', widget.task.startDate ?? '-'),
                  _buildInfoRow('Ngày hoàn thành', widget.task.deadline ?? '-'),
                  _buildInfoRow('Trạng thái', _getStatusText(widget.task.status)),
                  _buildInfoRow('Mức độ ưu tiên', _getPriorityText(widget.task.priority)),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space20),
            Text('Cập nhật tiến độ', style: semiBoldDefault.copyWith(fontSize: Dimensions.fontLarge)),
            const SizedBox(height: Dimensions.space15),
            Container(
              padding: const EdgeInsets.all(Dimensions.space15),
              decoration: BoxDecoration(
                color: ColorResources.colorWhite,
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                boxShadow: [
                  BoxShadow(
                    color: ColorResources.colorBlack.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiến độ hiện tại', style: regularDefault),
                      Text('${_progressValue.toInt()}%', style: semiBoldDefault.copyWith(color: ColorResources.primaryColor)),
                    ],
                  ),
                  Slider(
                    value: _progressValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: ColorResources.primaryColor,
                    inactiveColor: ColorResources.colorGrey.withOpacity(0.2),
                    label: '${_progressValue.toInt()}%',
                    onChanged: (double value) {
                      setState(() {
                        _progressValue = value;
                        if (value == 100) {
                          _status = 'done';
                        } else if (value > 0) {
                          _status = 'in_progress';
                        } else {
                          _status = 'open';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: Dimensions.space15),
                  GetBuilder<DeptDailyWorkController>(builder: (controller) {
                    if (controller.isSubmitLoading) {
                      return const RoundedLoadingBtn();
                    }
                    return RoundedButton(
                      text: 'Cập nhật',
                      press: () {
                        controller.updateStatus(
                          widget.task.id ?? '', 
                          _status, 
                          _progressValue.toInt()
                        ).then((_) {
                          Get.back(result: true);
                        });
                      },
                    );
                  })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: regularDefault.copyWith(color: ColorResources.colorGrey)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: semiBoldDefault),
          ),
        ],
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
}
