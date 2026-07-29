import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:chanhung/core/utils/color_resources.dart';

class CustomSvgPicture extends StatelessWidget {
  final String image;
  final double height, width;
  final Color color;
  final BoxFit? fit;
  const CustomSvgPicture(
      {super.key,
      this.fit,
      required this.image,
      this.height = 20,
      this.width = 20,
      this.color = ColorResources.primaryColor});

  Widget _placeholder() => SizedBox(width: width, height: height);

  @override
  Widget build(BuildContext context) {
    final colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    return fit != null
        ? SvgPicture.asset(
            image,
            fit: fit!,
            colorFilter: colorFilter,
            height: height,
            width: width,
            placeholderBuilder: (_) => _placeholder(),
          )
        : SvgPicture.asset(
            image,
            colorFilter: colorFilter,
            height: height,
            width: width,
            placeholderBuilder: (_) => _placeholder(),
          );
  }
}
