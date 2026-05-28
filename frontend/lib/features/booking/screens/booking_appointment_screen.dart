import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';

/// Booking appointment time selection screen allows users to choose
/// a date and time slot for their appointment.
class BookingAppointmentScreen extends StatefulWidget {
  const BookingAppointmentScreen({super.key});

  @override
  State<BookingAppointmentScreen> createState() => _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<DateTime> _availableDates = [
    DateTime.now(),
    DateTime.now().add(const Duration(days: 1)),
    DateTime.now().add(const Duration(days: 2)),
    DateTime.now().add(const Duration(days: 3)),
    DateTime.now().add(const Duration(days: 4)),
  ];

  final List<String> _timeSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your appointment time',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select a date and time that works best for you',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date Selection
              Text(
                'Select Date',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableDates.map((date) {
                    final isSelected = _selectedDate == date;
                    final dayName = _getDayName(date);
                    final dayNumber = date.day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusMd,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected
                                    ? AppColors.surface
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$dayNumber',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isSelected
                                    ? AppColors.surface
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Time Selection
              Text(
                'Select Time',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.5,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final time = _timeSlots[index];
                  final isSelected = _selectedTime == time;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusMd,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              CustomButton(
                label: 'Continue',
                onPressed: () {
                  if (_selectedDate != null && _selectedTime != null) {
                    // TODO: Navigate to booking confirmation
                  }
                },
                isEnabled: _selectedDate != null && _selectedTime != null,
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

  /// Get day name from date
  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
