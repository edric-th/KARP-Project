import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VisitHistoryCard extends StatelessWidget {
  final String date;
  final String hospital;
  final String doctor;
  final String specialization;
  final String waitTime;
  final bool isCompleted;
  final bool isLast;

  const VisitHistoryCard({
    super.key,
    required this.date,
    required this.hospital,
    required this.doctor,
    required this.specialization,
    required this.waitTime,
    this.isCompleted = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.successGreen : AppColors.borderMedium,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppColors.primaryGreen : AppColors.borderMedium,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: AppColors.borderLight,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen,
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hospital,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$doctor • $specialization',
                  style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Wait time: $waitTime',
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
