import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class QueueTokenScreen extends StatelessWidget {
  final QueueModel queue;
  const QueueTokenScreen({super.key, required this.queue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Your Queue Token'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Token card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Column(
                children: [
                  Text(
                    'TOKEN NUMBER',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${queue.queueNumber}',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      queue.status == QueueStatus.active
                          ? '🟢 Active'
                          : queue.status == QueueStatus.waiting
                              ? '🟡 Waiting'
                              : '✅ Completed',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Queue info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.local_hospital_rounded,
                    label: 'Hospital',
                    value: queue.hospitalName,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'Doctor',
                    value: queue.doctorName,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Department',
                    value: queue.department,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.group_rounded,
                    label: 'People Ahead',
                    value: '${queue.totalAhead}',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.timer_rounded,
                    label: 'Est. Wait',
                    value: '~${queue.estimatedMinutes} min',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Now Serving',
                    value: '#${queue.currentNumber}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Progress indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardGreenBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queue Progress',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${((queue.currentNumber / queue.queueNumber) * 100).clamp(0, 100).toInt()}%',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (queue.currentNumber / queue.queueNumber).clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: AppColors.cardGreenMedium,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'View Queue Details',
              onTap: () => Navigator.pushNamed(
                context,
                '/queue-detail',
                arguments: queue,
              ),
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Back to Home',
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cardGreenLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
