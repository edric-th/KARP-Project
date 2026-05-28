import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Custom elevated button widget following Material Design 3.
/// Used for primary actions throughout the app.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = AppSpacing.buttonHeightMd,
    this.icon,
  });

  /// Button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is enabled
  final bool isEnabled;

  /// Optional width (if null, uses available space)
  final double? width;

  /// Button height (default: 40px)
  final double height;

  /// Optional leading icon
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? AppColors.onPrimary : AppColors.textDisabled,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSm),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom outlined button widget following Material Design 3.
/// Used for secondary actions throughout the app.
class CustomOutlinedButton extends StatelessWidget {
  const CustomOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = AppSpacing.buttonHeightMd,
    this.icon,
  });

  /// Button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is enabled
  final bool isEnabled;

  /// Optional width (if null, uses available space)
  final double? width;

  /// Button height (default: 40px)
  final double height;

  /// Optional leading icon
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? AppColors.primary : AppColors.textDisabled,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSm),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: isEnabled ? AppColors.primary : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom text button widget following Material Design 3.
/// Used for tertiary/subtle actions throughout the app.
class CustomTextButton extends StatelessWidget {
  const CustomTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
  });

  /// Button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button is enabled
  final bool isEnabled;

  /// Optional leading icon
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (isEnabled && !isLoading) ? onPressed : null,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isEnabled ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: isEnabled ? AppColors.primary : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
    );
  }
}
