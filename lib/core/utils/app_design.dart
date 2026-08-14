import 'package:flutter/material.dart';

/// Shared visual language for the refreshed ERP interface.
abstract final class AppDesign {
  static const Color ink = Color(0xFF17262A);
  static const Color mutedInk = Color(0xFF4A6572);
  static const Color canvas = Color(0xFFF2F3F8);
  static const Color darkCanvas = Color(0xFF151922);
  static const Color accent = Color(0xFF00BBC2);
  static const Color accentBlue = Color(0xFF2633C5);
  static const Color brightBlue = Color(0xFF00BBC2);

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double pagePadding = 16;

  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: .06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static LinearGradient cardGradient(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, Colors.white, .18)!, color],
      );
}
