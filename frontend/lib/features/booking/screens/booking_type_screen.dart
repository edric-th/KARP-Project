import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';

/// Booking type selection screen allows users to choose between
/// different appointment booking options (e.g., consultation, follow-up, emergency).
class BookingTypeScreen extends StatefulWidget {
  const BookingTypeScreen({super.key});

  @override
  State<BookingTypeScreen> createState() => _BookingTypeScreenState();
}

class _BookingTypeScreenState extends State<BookingTypeScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Appointment Type'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What type of appointment do you need?',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select the type of service you require',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Consultation
              _buildTypeCard(
                type: 'consultation',
                title: 'New Consultation',
                description: 'Schedule a new appointment with a doctor',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              // Follow-up
              _buildTypeCard(
                type: 'followup',
                title: 'Follow-up Visit',
                description: 'Schedule a follow-up with your previous doctor',
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              // Check-up
              _buildTypeCard(
                type: 'checkup',
                title: 'General Check-up',
                description: 'Routine health check-up and consultation',
                icon: Icons.favorite_border,
              ),
              const SizedBox(height: AppSpacing.md),

              // Lab Tests
              _buildTypeCard(
                type: 'labtest',
                title: 'Lab Tests',
                description: 'Book laboratory tests and procedures',
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              CustomButton(
                label: 'Continue',
                onPressed: () {
                  if (_selectedType != null) {
                    // TODO: Navigate to specialist selection
                  }
                },
                isEnabled: _selectedType != null,
              ),
              const SizedBox(height: AppSpacing.md),

              CustomOutlinedButton(
                label: 'Cancel',
                onPressed: () {
                  // TODO: Navigate back
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a selectable type card
  Widget _buildTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: AppSpacing.iconLg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: AppColors.textTertiary,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
