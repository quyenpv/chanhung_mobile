import 'package:flutter/material.dart';
import '../../../core/utils/url_container.dart';
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
    final logoPath = _resolveLogoPath(logo);

    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return SizedBox(
        height: height,
        child: Image.network(
          logoPath,
          fit: fit,
          color: color,
          colorBlendMode: color == null ? null : BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackLogo();
          },
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Image.asset(
        logoPath,
        fit: fit,
        color: color,
        colorBlendMode: color == null ? null : BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackLogo();
        },
      ),
    );
  }

  String _resolveLogoPath(String? value) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return MyImages.appLogo;
    if (path.startsWith('assets/') ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) return '${UrlContainer.domainUrl}$path';
    return '${UrlContainer.systemImgUrl}$path';
  }

  Widget _fallbackLogo() => Image.asset(
        MyImages.appLogo,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: color == null ? null : BlendMode.srcIn,
      );
}
