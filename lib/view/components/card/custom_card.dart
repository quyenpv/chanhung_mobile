import 'package:flutter/material.dart';
import 'package:chanhung/core/utils/dimensions.dart';
import 'package:chanhung/core/utils/color_resources.dart';
import 'package:chanhung/core/utils/util.dart';
import 'package:chanhung/core/utils/app_design.dart';

class CustomCard extends StatefulWidget {
  final double paddingLeft, paddingRight, paddingTop, paddingBottom;
  final double? width;
  final double radius;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPress;

  const CustomCard(
      {super.key,
      this.width,
      this.paddingLeft = Dimensions.space15,
      this.paddingRight = Dimensions.space15,
      this.paddingTop = Dimensions.space15,
      this.paddingBottom = Dimensions.space15,
      this.radius = AppDesign.radiusMedium,
      this.onPressed,
      this.isPress = false,
      required this.child});

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  @override
  Widget build(BuildContext context) {
    return widget.isPress
        ? GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: widget.width,
              padding: EdgeInsets.only(
                  left: widget.paddingLeft,
                  right: widget.paddingRight,
                  top: widget.paddingTop,
                  bottom: widget.paddingBottom),
              decoration: BoxDecoration(
                color: MyUtils.getCardBgColor(),
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: AppDesign.softShadow(Theme.of(context).shadowColor),
              ),
              child: widget.child,
            ),
          )
        : Container(
            width: widget.width,
            padding: EdgeInsets.only(
                left: widget.paddingLeft,
                right: widget.paddingRight,
                top: widget.paddingTop,
                bottom: widget.paddingBottom),
            decoration: BoxDecoration(
              color: MyUtils.getCardBgColor(),
              border: Border.all(
                color: ColorResources.borderColor.withValues(alpha: .55),
                width: .8,
              ),
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: AppDesign.softShadow(Theme.of(context).shadowColor),
            ),
            child: widget.child,
          );
  }
}
