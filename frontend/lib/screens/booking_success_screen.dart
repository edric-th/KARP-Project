import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final DoctorModel? doctor;
  final String? date;
  final String? time;

  const BookingSuccessScreen({
    super.key,
    this.doctor,
    this.date,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Success animation circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (ctx, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.primaryShadow,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Appointment Booked!',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                doctor != null
                    ? 'Your appointment with ${doctor!.name} on ${date ?? 'the selected date'} at ${time ?? 'the selected time'} has been confirmed.'
                    : 'Your appointment has been successfully booked. You will receive a confirmation notification shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              // Appointment details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardGreenBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Doctor',
                      value: doctor?.name ?? 'Dr. Assigned',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: date ?? 'Confirmed',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: time ?? 'Confirmed',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.local_hospital_rounded,
                      label: 'Hospital',
                      value: doctor?.hospital ?? 'Assigned',
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'View Appointments',
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Back to Home',
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardGreenLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
