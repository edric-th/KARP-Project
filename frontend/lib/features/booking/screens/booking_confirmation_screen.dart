import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';

/// Booking confirmation screen displays a summary of the appointment details
/// and allows users to confirm or modify their booking.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data - in a real app, this would come from navigation arguments or state
    const appointmentType = 'New Consultation';
    const doctorName = 'Dr. Rajesh Kumar';
    const speciality = 'General Medicine';
    const appointmentDate = 'May 1, 2026';
    const appointmentTime = '2:30 PM';
    const estimatedDuration = '30 minutes';
    const consultationFee = '₹500';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Appointment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Your Appointment',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please review the details before confirming',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Appointment Type Card
              _buildDetailCard(
                icon: Icons.medical_services_outlined,
                title: 'Appointment Type',
                value: appointmentType,
              ),
              const SizedBox(height: AppSpacing.md),

              // Doctor Card
              _buildDoctorCard(
                doctorName: doctorName,
                speciality: speciality,
              ),
              const SizedBox(height: AppSpacing.md),

              // Date and Time Card
              _buildDetailCard(
                icon: Icons.calendar_today_outlined,
                title: 'Date & Time',
                value: '$appointmentDate at $appointmentTime',
              ),
              const SizedBox(height: AppSpacing.md),

              // Duration Card
              _buildDetailCard(
                icon: Icons.schedule_outlined,
                title: 'Estimated Duration',
                value: estimatedDuration,
              ),
              const SizedBox(height: AppSpacing.md),

              // Consultation Fee Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consultation Fee',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          consultationFee,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: AppSpacing.iconLg,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Terms and Conditions
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusSm,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'I agree to the appointment terms and conditions',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              CustomButton(
                label: 'Confirm Appointment',
                onPressed: () {
                  // TODO: Submit booking and navigate to success screen
                },
              ),
              const SizedBox(height: AppSpacing.md),

              CustomOutlinedButton(
                label: 'Edit Details',
                onPressed: () {
                  // TODO: Navigate back to edit appointment details
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a detail card with icon, title, and value
  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
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
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build doctor card
  Widget _buildDoctorCard({
    required String doctorName,
    required String speciality,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: AppSpacing.iconLg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  speciality,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
