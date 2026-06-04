import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/booking_model.dart';
import 'package:frontend/models/profile_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/state_views.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      context.read<BookingsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final bookings = context.watch<BookingsProvider>();
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: CustomAppBar(title: 'Medical History'),
        body: LoadingView(),
      );
    }

    final visits = bookings.items.where((b) => b.isServed).toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Medical History'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<BookingsProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _PatientCard(profile: profile),
            const SizedBox(height: 24),
            const _SectionTitle('PAST VISITS'),
            const SizedBox(height: 12),
            if (bookings.loading && visits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: LoadingView(),
              )
            else if (visits.isEmpty)
              const _Empty('No past visits yet.')
            else
              ...visits.map((v) => _VisitCard(booking: v)),
            const SizedBox(height: 28),
            const _SectionTitle('CURRENT MEDICATIONS'),
            const SizedBox(height: 12),
            _InfoCard(
              children: profile.currentMedications.isEmpty
                  ? const [_InfoRow(label: 'Medications', value: 'None recorded', isLast: true)]
                  : profile.currentMedications.map((m) {
                      final name = (m['name'] ?? '').toString();
                      final dose = (m['dose'] ?? '').toString();
                      return _InfoRow(
                        label: name.isEmpty ? 'Medication' : name,
                        value: dose.isEmpty ? '—' : dose,
                        isLast: m == profile.currentMedications.last,
                      );
                    }).toList(),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('ALLERGIES & CONDITIONS'),
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                _InfoRow(
                  label: 'Allergies',
                  value: profile.allergies.isEmpty
                      ? 'None reported'
                      : profile.allergies.join(', '),
                ),
                _InfoRow(
                  label: 'Chronic Conditions',
                  value: profile.chronicConditions.isEmpty
                      ? 'None reported'
                      : profile.chronicConditions.join(', '),
                ),
                _InfoRow(
                  label: 'Blood Group',
                  value: profile.bloodGroup.isEmpty ? '—' : profile.bloodGroup,
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final ProfileModel profile;
  const _PatientCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final bits = <String>[
      if (profile.age != null) '${profile.age} yrs',
      if (profile.gender.isNotEmpty) profile.gender,
      if (profile.bloodGroup.isNotEmpty) profile.bloodGroup,
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(profile.initials,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(bits.isEmpty ? 'MeroPalo patient' : bits.join(' · '),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final BookingModel booking;
  const _VisitCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMM y').format(DateTime.tryParse(booking.bookingDate) ??
            booking.servedAt ??
            DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(booking.doctorName.isEmpty ? 'Consultation' : booking.doctorName,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Text(dateStr,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textMuted)),
            ],
          ),
          if (booking.hospitalName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(booking.hospitalName,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _tag('Token #${booking.tokenLabel}'),
              _tag(booking.appointmentType.label),
            ],
          ),
          if ((booking.diagnosis ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DOCTOR\'S NOTES',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Text(booking.diagnosis!,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.textMuted));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow(
      {required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ),
            Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
      );
}
