import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'models/models.dart';
import 'widgets/common/custom_button.dart';

class DoctorDetailScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Container(height: 300, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
                    const Spacer(),
                    GestureDetector(onTap: () {}, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20))),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.person_rounded, color: Colors.white, size: 52)),
                const SizedBox(height: 12),
                Text(doctor.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(doctor.specialty, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _HeaderStat(value: '${doctor.rating}', label: 'Rating', icon: Icons.star_rounded, iconColor: const Color(0xFFF59E0B)),
                  _Vdivider(),
                  _HeaderStat(value: '${doctor.reviewCount}', label: 'Reviews', icon: Icons.reviews_outlined, iconColor: Colors.white),
                  _Vdivider(),
                  _HeaderStat(value: '${doctor.experience}yr', label: 'Exp.', icon: Icons.work_outline_rounded, iconColor: Colors.white),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildInfoSection(),
                        const SizedBox(height: 20),
                        _buildAvailableSlots(context),
                        const SizedBox(height: 20),
                        _buildAbout(),
                        const SizedBox(height: 32),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/hospitals'),
                            icon: const Icon(Icons.queue_rounded, size: 18),
                            label: Text('Join Queue', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primary), foregroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: PrimaryButton(label: 'Book Appointment', height: 50, onTap: () => Navigator.pushNamed(context, '/book-appointment', arguments: doctor))),
                        ]),
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

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        _InfoRow(icon: Icons.local_hospital_outlined, label: 'Hospital', value: doctor.hospital),
        const Divider(height: 20),
        _InfoRow(icon: Icons.payments_outlined, label: 'Consultation Fee', value: doctor.consultFee),
        const Divider(height: 20),
        _InfoRow(icon: Icons.circle, label: 'Availability', value: doctor.isAvailable ? 'Available Today' : 'Not Available', valueColor: doctor.isAvailable ? AppColors.success : AppColors.error, iconColor: doctor.isAvailable ? AppColors.success : AppColors.error),
      ]),
    );
  }

  Widget _buildAvailableSlots(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Available Slots', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: doctor.availableSlots.map((time) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/book-appointment', arguments: doctor),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.cardGreenLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cardGreenBorder)),
          child: Text(time, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
      )).toList()),
    ]);
  }

  Widget _buildAbout() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      Text('${doctor.name} is a highly experienced ${doctor.specialty} specialist with ${doctor.experience} years of clinical practice at ${doctor.hospital}. Known for patient-centered care and diagnostic precision.',
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.7)),
    ]);
  }
}

class _HeaderStat extends StatelessWidget {
  final String value; final String label; final IconData icon; final Color iconColor;
  const _HeaderStat({required this.value, required this.label, required this.icon, required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
      Icon(icon, color: iconColor, size: 18), const SizedBox(height: 4),
      Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.7))),
    ]));
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2));
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color? valueColor; final Color? iconColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: iconColor ?? AppColors.primary, size: 18), const SizedBox(width: 10), Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)), const Spacer(), Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary))]);
  }
}