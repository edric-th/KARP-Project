import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/review_model.dart';
import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/services/doctor_service.dart';
import 'package:frontend/services/queue_service.dart';
import 'package:frontend/widgets/common/custom_button.dart';
import 'package:frontend/widgets/common/doctor_avatar.dart';

class DoctorDetailScreen extends StatefulWidget {
  final DoctorModel doctor;
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  List<ReviewModel> _reviews = [];
  QueueStatusModel? _queue;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doctorService = context.read<DoctorService>();
    final queueService = context.read<QueueService>();
    try {
      final results = await Future.wait([
        doctorService.reviews(widget.doctor.id),
        queueService.forDoctor(widget.doctor.id),
      ]);
      if (!mounted) return;
      setState(() {
        _reviews = results[0] as List<ReviewModel>;
        _queue = results[1] as QueueStatusModel;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Container(
              height: 320,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: doctor.photoUrl.trim().isEmpty
                      ? const Icon(Icons.person_rounded,
                          color: Colors.white, size: 52)
                      : ClipOval(
                          child: DoctorAvatar(
                            photoUrl: doctor.photoUrl,
                            size: 90,
                            borderRadius: -1,
                            iconSize: 52,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(doctor.name,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                    [doctor.specialty, doctor.hospital]
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _TopStat(
                      label: 'Rating',
                      value: doctor.rating > 0 ? '${doctor.rating}' : '—',
                      icon: Icons.star_rounded),
                  _vDivider(),
                  _TopStat(
                      label: 'Reviews',
                      value: '${doctor.reviewCount}',
                      icon: Icons.reviews_outlined),
                  _vDivider(),
                  _TopStat(
                      label: 'Experience',
                      value: doctor.experience > 0 ? '${doctor.experience}y' : '—',
                      icon: Icons.work_outline_rounded),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32))),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_queue != null) _buildLiveQueue(_queue!),
                            if (doctor.bio.isNotEmpty) ...[
                              const _SectionTitle('About'),
                              const SizedBox(height: 10),
                              Text(doctor.bio,
                                  style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.6)),
                              const SizedBox(height: 20),
                            ],
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border)),
                              child: Row(children: [
                                _InfoRow(
                                    icon: Icons.payments_outlined,
                                    label: 'Consultation Fee',
                                    value: doctor.fee.isEmpty ? '—' : doctor.fee),
                                const SizedBox(width: 16),
                                _InfoRow(
                                    icon: Icons.circle,
                                    label: 'Status',
                                    value: doctor.availableNow(DateTime.now())
                                        ? 'Available'
                                        : 'Not available now',
                                    valueColor:
                                        doctor.availableNow(DateTime.now())
                                            ? AppColors.success
                                            : AppColors.error),
                              ]),
                            ),
                            if (doctor.availabilityLabel.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _AvailabilityCard(doctor: doctor),
                            ],
                            if (doctor.availableSlots.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const _SectionTitle('Available Time Slots'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: doctor.availableSlots
                                    .map((slot) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardGreenLight,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color:
                                                    AppColors.cardGreenBorder),
                                          ),
                                          child: Text(slot,
                                              style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary)),
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            _SectionTitle('Reviews (${_reviews.length})'),
                            const SizedBox(height: 12),
                            _buildReviews(),
                            const SizedBox(height: 32),
                            PrimaryButton(
                              label: 'Book Appointment',
                              icon: const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 20),
                              onTap: () => Navigator.pushNamed(
                                  context, '/book-appointment',
                                  arguments: doctor),
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

  Widget _buildLiveQueue(QueueStatusModel q) {
    final nowServing = q.nowServing;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGreenBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${q.waitingCount} waiting in today\'s queue',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                    nowServing != null
                        ? 'Now serving token #${nowServing.tokenNumber}'
                        : 'No one is being served right now',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Loading reviews…',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
      );
    }
    if (_reviews.isEmpty) {
      return const Text('No reviews yet. Be the first after your visit!',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary));
    }
    return Column(
      children: _reviews.map((r) => _ReviewCard(review: r)).toList(),
    );
  }

  Widget _vDivider() => Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white30);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.patientName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 2),
              Text(review.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.text,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final DoctorModel doctor;
  const _AvailabilityCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final availableNow = doctor.availableNow(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: availableNow
            ? AppColors.cardGreenLight
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: availableNow
                ? AppColors.cardGreenBorder
                : AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            availableNow ? Icons.schedule_rounded : Icons.event_busy_rounded,
            color: availableNow ? AppColors.primary : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  availableNow
                      ? 'Available'
                      : 'Not available at the moment',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: availableNow
                        ? AppColors.primaryDark
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consults ${doctor.availabilityLabel}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _TopStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _TopStat(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 11, color: Colors.white60)),
      ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textMuted)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ));
}
