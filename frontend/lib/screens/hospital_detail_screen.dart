import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/dummy_data.dart';
import 'package:frontend/widgets/common/custom_button.dart';
import 'package:frontend/widgets/home/doctor_card.dart';

class HospitalDetailScreen extends StatelessWidget {
  final HospitalModel hospital;
  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final hospitalDoctors = DummyData.doctors
        .where((d) => d.hospital == hospital.name)
        .toList();
    final displayDoctors =
        hospitalDoctors.isEmpty ? DummyData.doctors.take(3).toList() : hospitalDoctors;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 12),
                Text(hospital.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text('${hospital.address} • ${hospital.distance}',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                ]),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _StatBadge(
                                label: 'Rating', value: '${hospital.rating}',
                                icon: Icons.star_rounded, color: const Color(0xFFF59E0B)),
                            const SizedBox(width: 10),
                            _StatBadge(
                                label: 'Reviews', value: '${hospital.reviewCount}',
                                icon: Icons.reviews_outlined, color: AppColors.info),
                            const SizedBox(width: 10),
                            _StatBadge(
                                label: 'Queue', value: '${hospital.currentQueue}',
                                icon: Icons.people_alt_outlined, color: AppColors.primary),
                          ]),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(children: [
                              _HRow(icon: Icons.access_time_rounded,
                                  label: 'Hours', value: hospital.openHours),
                              const Divider(height: 20),
                              _HRow(
                                icon: Icons.circle,
                                label: 'Status',
                                value: hospital.isOpen ? 'Open Now' : 'Closed',
                                valueColor: hospital.isOpen ? AppColors.success : AppColors.error,
                                iconColor: hospital.isOpen ? AppColors.success : AppColors.error,
                              ),
                              const Divider(height: 20),
                              _HRow(icon: Icons.phone_outlined,
                                  label: 'Phone', value: hospital.phone),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          Text('Specialties',
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: hospital.specialties.map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.cardGreenLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.cardGreenBorder),
                              ),
                              child: Text(s,
                                  style: TextStyle(fontFamily: 'Inter', 
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text('Available Doctors',
                              style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          ...displayDoctors.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DoctorCard(
                              doctor: d, isHorizontal: true,
                              onTap: () => Navigator.pushNamed(context,
                                  '/doctor-detail', arguments: d),
                            ),
                          )),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Join Queue at ${hospital.name}',
                            icon: const Icon(Icons.queue_rounded,
                                color: Colors.white, size: 20),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Joined queue at ${hospital.name}!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
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
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatBadge({required this.label, required this.value,
      required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 16,
            fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textMuted)),
      ]),
    ),
  );
}

class _HRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor, iconColor;
  const _HRow({required this.icon, required this.label,
      required this.value, this.valueColor, this.iconColor});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
    const SizedBox(width: 10),
    Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
    const Spacer(),
    Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 13,
        fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
  ]);
}
