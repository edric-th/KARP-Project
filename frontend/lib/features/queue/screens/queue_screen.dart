import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/info_card.dart';

/// Queue status screen displays the current queue information
/// and allows patients to track their position in the queue.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Token Display
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Your Token',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onPrimary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '#A-25',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Queue Stats
              Text(
                'Queue Information',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              InfoCard(
                title: 'Current Serving',
                value: '#A-17',
                icon: Icons.call_received,
                subtitle: 'Window 1 - Dr. Smith',
              ),
              const SizedBox(height: AppSpacing.md),

              InfoCard(
                title: 'People Ahead',
                value: '8',
                icon: Icons.people_outline,
                subtitle: 'Estimated wait: 15 minutes',
              ),
              const SizedBox(height: AppSpacing.md),

              InfoCard(
                title: 'Total in Queue',
                value: '32',
                icon: Icons.groups,
                subtitle: 'Updated 2 minutes ago',
              ),
              const SizedBox(height: AppSpacing.lg),

              // Upcoming Tokens
              Text(
                'Next Tokens',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              _buildTokenItem('#A-18', 'Next (Window 1)'),
              const SizedBox(height: AppSpacing.sm),
              _buildTokenItem('#A-19', 'Window 2'),
              const SizedBox(height: AppSpacing.sm),
              _buildTokenItem('#A-20', 'Window 3'),
              const SizedBox(height: AppSpacing.sm),
              _buildTokenItem('#A-21', 'Waiting'),
              const SizedBox(height: AppSpacing.lg),

              // Department Info
              Text(
                'Department Details',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Department',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'General Medicine',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Floor',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '2nd Floor, Window 1-3',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Operating Hours',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '9:00 AM - 5:00 PM',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Info Message
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  border: Border.all(
                    color: AppColors.info,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: AppSpacing.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Queue updates automatically every minute. Please be ready when your token is called.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a token item for the next tokens list
  Widget _buildTokenItem(String token, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            ),
            child: Text(
              token,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            status,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
