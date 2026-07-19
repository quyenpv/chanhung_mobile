import 'package:flutter/material.dart';
import '../../../core/utils/images.dart';

class AppLogoImage extends StatelessWidget {
  const AppLogoImage({
    super.key,
    required this.logo,
    required this.height,
    this.color,
    this.fit = BoxFit.fitHeight,
  });

  final String? logo;
  final double height;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final logoPath = (logo != null && logo!.isNotEmpty) ? logo! : MyImages.appLogo;

    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return SizedBox(
        height: height,
        child: Image.network(
          logoPath,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              MyImages.appLogo,
              height: height,
              fit: fit,
            );
          },
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Image.asset(
        logoPath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            MyImages.appLogo,
            height: height,
            fit: fit,
          );
        },
      ),
    );
  }
}
