import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Reusable info card widget for displaying information with an icon.
/// Used for queue status, appointment details, and general information display.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
    this.backgroundColor = AppColors.surface,
    this.borderColor,
    this.onTap,
    this.trailing,
  });

  /// Card title
  final String title;

  /// Main value/content
  final String value;

  /// Leading icon
  final IconData? icon;

  /// Optional subtitle text
  final String? subtitle;

  /// Background color
  final Color backgroundColor;

  /// Optional border color
  final Color? borderColor;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., badge, status indicator)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: hasBorder
              ? Border.all(
                  color: borderColor!,
                  width: 1.5,
                )
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: !hasBorder
              ? [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: AppSpacing.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTextStyles.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Status badge widget for displaying appointment/queue status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  /// Status type
  final AppointmentStatus status;

  /// Label text
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors['background'] as Color,
        border: Border.all(color: colors['border'] as Color, width: 1.0),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: colors['text'] as Color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed:
        return {
          'background': AppColors.success.withOpacity(0.1),
          'border': AppColors.success,
          'text': AppColors.success,
        };
      case AppointmentStatus.inProgress:
        return {
          'background': AppColors.info.withOpacity(0.1),
          'border': AppColors.info,
          'text': AppColors.info,
        };
      case AppointmentStatus.pending:
        return {
          'background': AppColors.warning.withOpacity(0.1),
          'border': AppColors.warning,
          'text': AppColors.warning,
        };
      case AppointmentStatus.cancelled:
        return {
          'background': AppColors.error.withOpacity(0.1),
          'border': AppColors.error,
          'text': AppColors.error,
        };
    }
  }
}

/// Enum for appointment/queue status
enum AppointmentStatus {
  completed,
  inProgress,
  pending,
  cancelled,
}

/// Doctor card widget for displaying doctor information
class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.name,
    required this.speciality,
    this.avatarUrl,
    this.rating,
    this.experience,
    this.onTap,
  });

  /// Doctor name
  final String name;

  /// Doctor speciality
  final String speciality;

  /// Avatar image URL
  final String? avatarUrl;

  /// Rating (0-5)
  final double? rating;

  /// Years of experience
  final int? experience;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: AppSpacing.avatarMd,
              height: AppSpacing.avatarMd,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: AppSpacing.iconLg,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    speciality,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (experience != null || rating != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (experience != null) ...[
                          Icon(
                            Icons.work_outline,
                            size: AppSpacing.iconSm,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$experience yrs',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (rating != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Icon(
                            Icons.star_rounded,
                            size: AppSpacing.iconSm,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            rating.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Trailing arrow
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}
