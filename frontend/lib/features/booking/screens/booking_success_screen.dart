import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';

/// Booking success screen displays a confirmation message after a successful
/// appointment booking and shows the booking details.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data - in a real app, this would come from navigation arguments or state
    const appointmentId = 'APT-2026-001234';
    const doctorName = 'Dr. Rajesh Kumar';
    const appointmentDate = 'May 1, 2026';
    const appointmentTime = '2:30 PM';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Success Icon Animation placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 80,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Success Title
                Text(
                  'Appointment Booked!',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Success Message
                Text(
                  'Your appointment has been successfully scheduled. We have sent you a confirmation email.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Booking Details Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                  ),
                  child: Column(
                    children: [
                      // Appointment ID
                      _buildDetailRow(
                        label: 'Appointment ID',
                        value: appointmentId,
                        isDark: false,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Doctor
                      _buildDetailRow(
                        label: 'Doctor',
                        value: doctorName,
                        isDark: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Date
                      _buildDetailRow(
                        label: 'Date',
                        value: appointmentDate,
                        isDark: false,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Time
                      _buildDetailRow(
                        label: 'Time',
                        value: appointmentTime,
                        isDark: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Important Notes Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.05),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outlined,
                            color: AppColors.warning,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Important Notes',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildBulletPoint(
                        'Please arrive 10 minutes before your appointment',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildBulletPoint(
                        'Carry a valid ID and insurance card',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildBulletPoint(
                        'In case of cancellation, notify at least 24 hours in advance',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                CustomButton(
                  label: 'Back to Home',
                  onPressed: () {
                    // TODO: Navigate to home screen
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                CustomOutlinedButton(
                  label: 'View My Appointments',
                  onPressed: () {
                    // TODO: Navigate to appointments list
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a detail row with label and value
  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariant : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a bullet point
  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(
            top: AppSpacing.xs,
            right: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
