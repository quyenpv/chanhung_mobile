import 'package:flutter/material.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';

class CustomDivider extends StatelessWidget {
  final double space;
  final Color? color;

  const CustomDivider({super.key, this.space = Dimensions.space20, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: space),
        Divider(
            color: color?.withValues(alpha: 0.3) ??
                ColorResources.getDividerColor().withValues(alpha: 0.3),
            height: 0.5,
            thickness: 0.5),
        SizedBox(height: space),
      ],
    );
  }
}
