import 'package:chanhung/core/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chanhung/core/utils/color_resources.dart';

class RoundedButton extends StatelessWidget {
  final bool isColorChange;
  final String text;
  final VoidCallback press;
  final Color color;
  final Color? textColor;
  final double width;
  final double horizontalPadding;
  final double verticalPadding;
  final double cornerRadius;
  final bool isOutlined;
  final Widget? child;

  const RoundedButton({
    super.key,
    this.isColorChange = false,
    this.width = 1,
    this.child,
    this.cornerRadius = 999,
    required this.text,
    required this.press,
    this.isOutlined = false,
    this.horizontalPadding = 35,
    this.verticalPadding = 18,
    this.color = ColorResources.primaryColor,
    this.textColor = ColorResources.colorWhite,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return child != null
        ? InkWell(
            onTap: press,
            splashColor: ColorResources.getScreenBgColor(),
            child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                width: size.width * width,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    color: isColorChange
                        ? color
                        : ColorResources.getPrimaryButtonColor()),
                child: Center(
                    child: Text(text.tr,
                        style: regularDefault.copyWith(
                            color: isColorChange
                                ? textColor
                                : ColorResources
                                    .getPrimaryButtonTextColor())))),
          )
        : isOutlined
            ? SizedBox(
                width: size.width * width,
                child: OutlinedButton(
                  onPressed: press,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                  ),
                  child: Text(text.tr),
                ),
              )
            : SizedBox(
                width: size.width * width,
                child: ElevatedButton(
                  onPressed: press,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shadowColor: ColorResources.transparentColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding),
                      textStyle: regularDefault.copyWith(color: textColor)),
                  child: Text(
                    text.tr,
                    style: TextStyle(color: textColor),
                  ),
                ),
              );
  }
}
