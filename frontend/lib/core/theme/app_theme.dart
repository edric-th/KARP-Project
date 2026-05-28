import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// App theme configuration following Material Design 3.
/// This file provides the complete theme for the Mero Palo application.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Returns the light theme for the app
  static ThemeData get lightTheme {
    final colorScheme = AppColors.getColorScheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // ========================================================================
      // Scaffold Theme
      // ========================================================================
      scaffoldBackgroundColor: AppColors.background,

      // ========================================================================
      // AppBar Theme
      // ========================================================================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppSpacing.elevation2,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.onPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.onPrimary,
          size: AppSpacing.iconMd,
        ),
      ),

      // ========================================================================
      // Text Theme
      // ========================================================================
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // ========================================================================
      // Elevated Button Theme
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: AppSpacing.elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
        ),
      ),

      // ========================================================================
      // Outlined Button Theme
      // ========================================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
        ),
      ),

      // ========================================================================
      // Text Button Theme
      // ========================================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
        ),
      ),

      // ========================================================================
      // Card Theme
      // ========================================================================
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppSpacing.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        margin: const EdgeInsets.all(AppSpacing.cardMargin),
      ),

      // ========================================================================
      // Input Decoration Theme
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // ========================================================================
      // Floating Action Button Theme
      // ========================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppSpacing.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
        ),
      ),

      // ========================================================================
      // Bottom Sheet Theme
      // ========================================================================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevation5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.borderRadiusLg),
            topRight: Radius.circular(AppSpacing.borderRadiusLg),
          ),
        ),
      ),

      // ========================================================================
      // Dialog Theme
      // ========================================================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevation5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // ========================================================================
      // Chip Theme
      // ========================================================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.textDisabled,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onPrimary,
        ),
        brightness: Brightness.light,
      ),

      // ========================================================================
      // Icon Theme
      // ========================================================================
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSpacing.iconMd,
      ),

      // ========================================================================
      // Divider Theme
      // ========================================================================
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.0,
        space: AppSpacing.md,
      ),

      // ========================================================================
      // Bottom Navigation Bar Theme
      // ========================================================================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevation4,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),

      // ========================================================================
      // Snackbar Theme
      // ========================================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        elevation: AppSpacing.elevation3,
      ),

      // ========================================================================
      // Progress Indicator Theme
      // ========================================================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: AppColors.surfaceVariant,
      ),
    );
  }

  /// Returns the dark theme for the app (if needed in future)
  static ThemeData get darkTheme {
    final colorScheme = AppColors.getColorScheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1C1C1C),
      // Additional dark theme configurations can be added here
    );
  }
}
