import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QueueStatusItem extends StatelessWidget {
  final int tokenNumber;
  final String status;
  final String patientType;
  final String? estimatedTime;
  final bool isCurrentUser;
  final String? additionalInfo;

  const QueueStatusItem({
    super.key,
    required this.tokenNumber,
    required this.status,
    required this.patientType,
    this.estimatedTime,
    this.isCurrentUser = false,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white : AppColors.lightPurpleBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: isCurrentUser
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Text(
            tokenNumber.toString().padLeft(3, '0'),
            style: TextStyle(
              color: isCurrentUser ? AppColors.primaryGreen : AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCurrentUser) ...[
                      const Text(
                        'YOU',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    _buildStatusChip(status),
                    const SizedBox(width: AppSpacing.sm),
                    _buildPatientTypeChip(patientType),
                  ],
                ),
                if (additionalInfo != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    additionalInfo!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCurrentUser
                          ? AppColors.textMedium
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (estimatedTime != null)
            Text(
              estimatedTime!,
              style: TextStyle(
                color: isCurrentUser ? AppColors.textMedium : AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'waiting':
        bgColor = AppColors.waitingOrange;
        textColor = AppColors.waitingOrangeText;
        break;
      case 'in consult':
        bgColor = AppColors.primaryGreen;
        textColor = AppColors.textWhite;
        break;
      default:
        bgColor = AppColors.chipGreen;
        textColor = AppColors.chipGreenText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPatientTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipGreen,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
