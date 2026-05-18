import 'package:flutter/material.dart';

/// App color constants using Material Design 3 color system.
/// All colors follow Material Design 3 guidelines for consistency and accessibility.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary brand colors
  static const Color primary = Color(0xFF006B5E); // Teal/Turquoise
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary

  // Secondary colors
  static const Color secondary = Color(0xFF4A6FA5); // Navy blue
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on secondary

  // Tertiary colors (accents)
  static const Color tertiary = Color(0xFF7D5260); // Rose/Mauve
  static const Color onTertiary = Color(0xFFFFFFFF); // White text on tertiary

  // Success state
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color onSuccess = Color(0xFFFFFFFF); // White text on success

  // Warning/Waiting state
  static const Color warning = Color(0xFFFFA500); // Orange
  static const Color onWarning = Color(0xFFFFFFFF); // White text on warning

  // Error state
  static const Color error = Color(0xFFB3261E); // Red (Material Design 3)
  static const Color onError = Color(0xFFFFFFFF); // White text on error

  // Background colors
  static const Color background = Color(0xFFFAFAFA); // Light gray background
  static const Color onBackground = Color(0xFF1C1C1C); // Dark text on background
  static const Color surface = Color(0xFFFFFFFF); // White surface
  static const Color onSurface = Color(0xFF1C1C1C); // Dark text on surface
  static const Color surfaceVariant = Color(0xFFEAEAEA); // Light variant surface

  // Text colors
  static const Color textPrimary = Color(0xFF1C1C1C); // Main text - Dark gray/black
  static const Color textSecondary = Color(0xFF6B6B6B); // Secondary text - Medium gray
  static const Color textTertiary = Color(0xFF9A9A9A); // Tertiary text - Light gray
  static const Color textDisabled = Color(0xFFCCCCCC); // Disabled text - Very light gray

  // Border and divider colors
  static const Color border = Color(0xFFE0E0E0); // Light border
  static const Color divider = Color(0xFFF0F0F0); // Light divider

  // Semantic colors
  static const Color info = Color(0xFF2196F3); // Blue for info
  static const Color completed = Color(0xFF4CAF50); // Green for completed
  static const Color pending = Color(0xFFFFA500); // Orange for pending
  static const Color inConsultation = Color(0xFF2196F3); // Blue for in consultation

  // Overlay colors
  static const Color overlay = Color(0x00000000); // Black overlay (transparent by default)
  static const Color overlayLight = Color(0x1F000000); // 12% black overlay
  static const Color overlayMedium = Color(0x4D000000); // 30% black overlay
  static const Color overlayDark = Color(0x80000000); // 50% black overlay

  /// Returns the Material ColorScheme based on Material Design 3
  static ColorScheme getColorScheme({bool isDark = false}) {
    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        tertiary: tertiary,
        onTertiary: onTertiary,
        error: error,
        onError: onError,
        background: const Color(0xFF1C1C1C),
        onBackground: const Color(0xFFFFFFFF),
        surface: const Color(0xFF2C2C2C),
        onSurface: const Color(0xFFFFFFFF),
      );
    }
    return ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      onTertiary: onTertiary,
      error: error,
      onError: onError,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
    );
  }
}
