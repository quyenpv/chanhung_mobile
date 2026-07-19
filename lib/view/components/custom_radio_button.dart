import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/style.dart';

class CustomRadioButton extends StatefulWidget {
  final String? title, selectedValue;
  final int selectedIndex;
  final List<String> list;
  final ValueChanged? onChanged;
  const CustomRadioButton({
    super.key,
    this.title,
    this.selectedIndex = 0,
    this.selectedValue,
    required this.list,
    this.onChanged,
  });

  @override
  State<CustomRadioButton> createState() => _CustomRadioButtonState();
}

class _CustomRadioButtonState extends State<CustomRadioButton> {
  @override
  Widget build(BuildContext context) {
    if (widget.list.isEmpty) {
      return Container();
    }
    return Column(
      children: [
        widget.title != null ? const SizedBox() : Text(widget.title ?? ''),
        RadioGroup<int>(
          groupValue: widget.selectedIndex,
          onChanged: (int? value) {
            if (value == null) {
              return;
            }
            setState(() {
              widget.onChanged?.call(value);
            });
          },
          child: Column(
            children:
                List<RadioListTile<int>>.generate(widget.list.length, (index) {
              return RadioListTile<int>(
                value: index,
                activeColor: ColorResources.primaryColor,
                title: Text(
                  widget.list[index].tr,
                  style:
                      regularDefault.copyWith(color: ColorResources.colorBlack),
                ),
                selected: index == widget.selectedIndex,
              );
            }),
          ),
        ),
      ],
    );
  }
}
