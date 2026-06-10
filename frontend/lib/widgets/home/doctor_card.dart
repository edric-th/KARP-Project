import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/doctor_avatar.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final bool isHorizontal;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal ? _buildHorizontal() : _buildVertical();
  }

  Widget _buildHorizontal() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            DoctorAvatar(
              photoUrl: doctor.photoUrl,
              size: 72,
              borderRadius: 16,
              iconSize: 38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${doctor.specialty} • ${doctor.hospital}',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (doctor.availabilityLabel.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _AvailabilityLine(doctor: doctor),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.rating}',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        ' (${doctor.reviewCount} reviews)',
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        doctor.fee,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVertical() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DoctorAvatar(
              photoUrl: doctor.photoUrl,
              width: double.infinity,
              height: 90,
              borderRadius: 14,
              iconSize: 44,
            ),
            const SizedBox(height: 10),
            Text(
              doctor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              doctor.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (doctor.availabilityTimeLabel.isNotEmpty) ...[
              const SizedBox(height: 5),
              _AvailabilityLine(doctor: doctor, compact: true),
            ],
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${doctor.rating}',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${doctor.experience}y',
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact "Consults Mon–Fri · 10:00 AM – 2:00 PM" line for doctor cards, with
/// a not-available-now state. [compact] shows just the time range (narrow card).
class _AvailabilityLine extends StatelessWidget {
  final DoctorModel doctor;
  final bool compact;
  const _AvailabilityLine({required this.doctor, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final availableNow = doctor.availableNow(DateTime.now());
    final label =
        compact ? doctor.availabilityTimeLabel : doctor.availabilityLabel;
    final color = availableNow ? AppColors.primary : AppColors.error;
    return Row(
      children: [
        Icon(
          availableNow ? Icons.schedule_rounded : Icons.event_busy_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            availableNow ? label : 'Closed now • $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: availableNow ? AppColors.textSecondary : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
