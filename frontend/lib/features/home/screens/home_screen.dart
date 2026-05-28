import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/info_card.dart';

/// Home screen of the Mero Palo application.
/// Displays hospital information, current queue status, and quick actions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mero Palo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Mero Palo',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hospital Queue Management System',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Queue Status Section
              Text(
                'Current Queue Status',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Queue Stats
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: 'Your Token',
                      value: '#A-25',
                      icon: Icons.confirmation_number,
                      subtitle: 'In queue',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: InfoCard(
                      title: 'Waiting Time',
                      value: '~15 min',
                      icon: Icons.schedule,
                      subtitle: 'Estimated',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: 'Ahead in Queue',
                      value: '8 people',
                      icon: Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: InfoCard(
                      title: 'Current',
                      value: '#A-17',
                      icon: Icons.call_received,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              CustomButton(
                label: 'Book Appointment',
                onPressed: () {
                  // TODO: Navigate to booking flow
                },
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: AppSpacing.md),

              CustomOutlinedButton(
                label: 'View Queue',
                onPressed: () {
                  // TODO: Navigate to queue status screen
                },
                icon: Icons.list_alt,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Departments Section
              Text(
                'Available Departments',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              // Department List
              _buildDepartmentItem('Cardiology', Icons.favorite_border),
              const SizedBox(height: AppSpacing.sm),
              _buildDepartmentItem('Neurology', Icons.psychology),
              const SizedBox(height: AppSpacing.sm),
              _buildDepartmentItem('Orthopedics', Icons.accessibility),
              const SizedBox(height: AppSpacing.sm),
              _buildDepartmentItem('Pediatrics', Icons.child_friendly),
              const SizedBox(height: AppSpacing.sm),
              _buildDepartmentItem('General Medicine', Icons.local_hospital),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a department list item
  Widget _buildDepartmentItem(String name, IconData icon) {
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
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textTertiary,
            size: AppSpacing.iconSm,
          ),
        ],
      ),
    );
  }
}
