import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFF1D9E75);
  static const Color primaryMedium = Color(0xFF38AA86);
  static const Color primarySoft = Color(0xFF5CB99C);
  static const Color primaryDark = Color(0xFF0A4D3C);
  static const Color accent = Color(0xFF00D4AA);

  static const Color backgroundLight = Color(0xFFF0FAF6);
  static const Color backgroundDark = Color(0xFF061410);
  static const Color backgroundDarkSecondary = Color(0xFF0A2818);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color cardGreenLight = Color(0xFFE1F5EE);
  static const Color cardGreenMedium = Color(0xFFC9EEE2);
  static const Color cardGreenBorder = Color(0xFFD1E6E0);

  static const Color textPrimary = Color(0xFF0A1F1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xFF9FE1CB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  static const Color success = Color(0xFF1D9E75);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color darkCard = Color(0xFF0F2D22);
  static const Color darkCardBorder = Color(0xFF1A4A35);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF061410), Color(0xFF0A2818)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D9E75), Color(0xFF38AA86)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
