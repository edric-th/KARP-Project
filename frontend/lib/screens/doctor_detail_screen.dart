import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorModel doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Container(height: 320, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white12,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white12,
                          borderRadius: BorderRadius.circular(12)),
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favourites'),
                              backgroundColor: AppColors.primary),
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 12),
                Text(doctor.name,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 22,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${doctor.specialty} • ${doctor.hospital}',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _TopStat(label: 'Rating', value: '${doctor.rating}', icon: Icons.star_rounded),
                  _vDivider(),
                  _TopStat(label: 'Reviews', value: '${doctor.reviewCount}', icon: Icons.reviews_outlined),
                  _vDivider(),
                  _TopStat(label: 'Experience', value: '${doctor.experience}y', icon: Icons.work_outline_rounded),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('About', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        Text(doctor.bio, style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                            color: AppColors.textSecondary, height: 1.6)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            _InfoRow(icon: Icons.payments_outlined, label: 'Consultation Fee',
                                value: doctor.fee),
                            const SizedBox(width: 16),
                            _InfoRow(icon: Icons.circle, label: 'Status',
                                value: doctor.isAvailable ? 'Available' : 'Unavailable',
                                valueColor: doctor.isAvailable ? AppColors.success : AppColors.error),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        Text('Available Time Slots', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: doctor.availableSlots.map((slot) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardGreenLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardGreenBorder),
                            ),
                            child: Text(slot, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                fontWeight: FontWeight.w600, color: AppColors.primary)),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Book Appointment',
                          icon: const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 20),
                          onTap: () => Navigator.pushNamed(context, '/book-appointment',
                              arguments: doctor),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Join Queue with ${doctor.name}',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Joined queue with ${doctor.name}!'),
                                backgroundColor: AppColors.primary),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white30);
}

class _TopStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _TopStat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.white70, size: 16),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white60)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
          color: valueColor ?? AppColors.textPrimary)),
    ],
  ));
}
