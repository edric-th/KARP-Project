import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

// ─── PRIMARY BUTTON ───────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white24,
        child: Ink(
          width: width ?? double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: onTap == null
                ? null
                : AppColors.primaryGradient,
            color: onTap == null ? AppColors.border : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isLoading
                ? []
                : AppColors.primaryShadow,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── SECONDARY BUTTON ─────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final Color? borderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        child: Ink(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: borderColor ?? AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── GHOST BUTTON ─────────────────────────────────────────────────────────────

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final double? fontSize;

  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: fontSize ?? 13,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
