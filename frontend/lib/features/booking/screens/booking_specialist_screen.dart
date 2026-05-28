import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';

/// Booking specialist selection screen allows users to choose
/// a doctor/specialist for their appointment.
class BookingSpecialistScreen extends StatefulWidget {
  const BookingSpecialistScreen({super.key});

  @override
  State<BookingSpecialistScreen> createState() => _BookingSpecialistScreenState();
}

class _BookingSpecialistScreenState extends State<BookingSpecialistScreen> {
  String? _selectedDoctorId;

  final List<Map<String, dynamic>> _doctors = [
    {
      'id': '1',
      'name': 'Dr. Rajesh Kumar',
      'speciality': 'General Medicine',
      'experience': 12,
      'rating': 4.8,
      'availability': 'Available Today',
      'nextSlot': '2:30 PM',
    },
    {
      'id': '2',
      'name': 'Dr. Priya Sharma',
      'speciality': 'Cardiology',
      'experience': 10,
      'rating': 4.9,
      'availability': 'Available Tomorrow',
      'nextSlot': '10:00 AM',
    },
    {
      'id': '3',
      'name': 'Dr. Amit Singh',
      'speciality': 'Orthopedics',
      'experience': 8,
      'rating': 4.7,
      'availability': 'Available Today',
      'nextSlot': '3:00 PM',
    },
    {
      'id': '4',
      'name': 'Dr. Neha Gupta',
      'speciality': 'Pediatrics',
      'experience': 6,
      'rating': 4.6,
      'availability': 'Available in 2 days',
      'nextSlot': '11:00 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Specialist'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Specialist',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select a doctor based on availability and experience',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Doctors List
              ..._doctors.map((doctor) {
                final isSelected = _selectedDoctorId == doctor['id'];
                return Column(
                  children: [
                    _buildDoctorCard(doctor, isSelected),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
              }).toList(),

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              CustomButton(
                label: 'Continue',
                onPressed: () {
                  if (_selectedDoctorId != null) {
                    // TODO: Navigate to booking confirmation
                  }
                },
                isEnabled: _selectedDoctorId != null,
              ),
              const SizedBox(height: AppSpacing.md),

              CustomOutlinedButton(
                label: 'Back',
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

  /// Build a doctor card
  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDoctorId = doctor['id'];
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
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

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['name'],
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    doctor['speciality'],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Rating and Experience
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: AppSpacing.iconSm,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${doctor['rating']}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.work_outline,
                        size: AppSpacing.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${doctor['experience']} yrs',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Availability
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    ),
                    child: Text(
                      '${doctor['availability']} • ${doctor['nextSlot']}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
