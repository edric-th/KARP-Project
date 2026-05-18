import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App text styles constants using Material Design 3 typography system.
/// All text styles follow Material Design 3 guidelines for typography.
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  // Font family
  static const String fontFamily = 'Roboto'; // Default Material Design 3 font

  // ============================================================================
  // Display Styles (Large headline text)
  // ============================================================================

  /// Display Large - 57px / 400 (Regular)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12, // 64/57
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  /// Display Medium - 45px / 400 (Regular)
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16, // 52/45
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Display Small - 36px / 400 (Regular)
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22, // 44/36
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // Headline Styles
  // ============================================================================

  /// Headline Large - 32px / 700 (Bold)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // 40/32
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Headline Medium - 28px / 700 (Bold)
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29, // 36/28
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Headline Small - 24px / 700 (Bold)
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33, // 32/24
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // Title Styles
  // ============================================================================

  /// Title Large - 22px / 500 (Medium)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27, // 28/22
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Title Medium - 16px / 600 (Semi-Bold)
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5, // 24/16
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  /// Title Small - 14px / 600 (Semi-Bold)
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43, // 20/14
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // Body Styles
  // ============================================================================

  /// Body Large - 16px / 400 (Regular)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24/16
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  /// Body Medium - 14px / 500 (Medium)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43, // 20/14
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  /// Body Small - 12px / 400 (Regular)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.67, // 20/12
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // ============================================================================
  // Label Styles (Buttons, tags, etc.)
  // ============================================================================

  /// Label Large - 14px / 600 (Semi-Bold)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43, // 20/14
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// Label Medium - 12px / 600 (Semi-Bold)
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.67, // 20/12
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Label Small - 11px / 600 (Semi-Bold)
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45, // 16/11
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // Custom Styles for App-specific use cases
  // ============================================================================

  /// Button Text - 16px / 600 (Semi-Bold)
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5, // 24/16
    letterSpacing: 0.5,
    color: AppColors.onPrimary,
  );

  /// Caption - 12px / 400 (Regular) - For small secondary text
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.67, // 20/12
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  /// Overline - 12px / 600 (Semi-Bold) - For uppercase labels
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.67, // 20/12
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  // ============================================================================
  // Secondary Text Variants
  // ============================================================================

  /// Body Large Secondary
  static const TextStyle bodyLargeSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppColors.textSecondary,
  );

  /// Body Medium Secondary
  static const TextStyle bodyMediumSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
  );

  /// Headline Small Secondary
  static const TextStyle headlineSmallSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );
}
