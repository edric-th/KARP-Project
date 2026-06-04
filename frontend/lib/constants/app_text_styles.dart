import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display
  static TextStyle get displayLarge => TextStyle(fontFamily: 'Inter', 
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
        height: 1.1,
      );

  static TextStyle get displayMedium => TextStyle(fontFamily: 'Inter', 
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.15,
      );

  // Headings
  static TextStyle get h1 => TextStyle(fontFamily: 'Inter', 
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => TextStyle(fontFamily: 'Inter', 
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => TextStyle(fontFamily: 'Inter', 
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get h4 => TextStyle(fontFamily: 'Inter', 
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // Subtitles
  static TextStyle get subtitle1 => TextStyle(fontFamily: 'Inter', 
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitle2 => TextStyle(fontFamily: 'Inter', 
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // Body
  static TextStyle get body1 => TextStyle(fontFamily: 'Inter', 
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body2 => TextStyle(fontFamily: 'Inter', 
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get body2Medium => TextStyle(fontFamily: 'Inter', 
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // Captions
  static TextStyle get caption => TextStyle(fontFamily: 'Inter', 
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get captionMedium => TextStyle(fontFamily: 'Inter', 
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle get label => TextStyle(fontFamily: 'Inter', 
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );

  // Buttons
  static TextStyle get buttonLarge => TextStyle(fontFamily: 'Inter', 
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get buttonMedium => TextStyle(fontFamily: 'Inter', 
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get buttonSmall => TextStyle(fontFamily: 'Inter', 
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // On Dark
  static TextStyle get bodyOnDark => TextStyle(fontFamily: 'Inter', 
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textOnDark,
      );

  static TextStyle get captionOnDark => TextStyle(fontFamily: 'Inter', 
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnDarkSecondary,
      );
}
