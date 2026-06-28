import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final DoctorModel? doctor;
  final String? date;
  final String? time;
  final AppointmentType? appointmentType;
  final String? speciality;
  final int? tokenNumber;
  final int? estimatedWaitMinutes;
  final String? expectedCallAt; // ISO-8601 from the backend (fallback)
  final bool notifyMe;
  final String? patientName;
  final String? hospitalName; // shown for online (reception) tokens — no doctor

  const BookingSuccessScreen({
    super.key,
    this.doctor,
    this.date,
    this.time,
    this.appointmentType,
    this.speciality,
    this.tokenNumber,
    this.estimatedWaitMinutes,
    this.expectedCallAt,
    this.notifyMe = true,
    this.patientName,
    this.hospitalName,
  });

  String get _token => (tokenNumber ?? 0).toString().padLeft(3, '0');

  String get _waitTime {
    final mins = estimatedWaitMinutes;
    if (mins == null) return 'Calculating…';
    if (mins <= 0) return 'Now';
    if (mins < 60) return '~$mins mins';
    final hours = (mins / 60).round();
    return '~$hours hour${hours > 1 ? 's' : ''}';
  }

  /// Real-world clock time the patient is expected to be called. Uses the
  /// backend's availability-anchored expectedCallAt (so a 7 AM booking for a
  /// doctor who opens at 10 AM reads "10:xx AM"), falling back to now + wait
  /// only when expectedCallAt isn't available.
  String get _turnTime {
    final now = DateTime.now();
    DateTime? turn = expectedCallAt != null
        ? DateTime.tryParse(expectedCallAt!)?.toLocal()
        : null;
    if (turn == null && estimatedWaitMinutes != null) {
      turn = now.add(Duration(minutes: estimatedWaitMinutes!));
    }
    if (turn == null) return 'Calculating…';
    final sameDay =
        turn.year == now.year && turn.month == now.month && turn.day == now.day;
    return sameDay
        ? '${DateFormat('h:mm a').format(turn)}, Today'
        : DateFormat('EEE d MMM, h:mm a').format(turn);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (patientName == null || patientName!.trim().isEmpty)
        ? 'Patient'
        : patientName!;
    final spec = speciality ?? doctor?.specialty ?? 'General Medicine';
    // Reception (online) tokens have no doctor — show the hospital/desk instead.
    final docName = doctor?.name ??
        (hospitalName != null && hospitalName!.trim().isNotEmpty
            ? hospitalName!
            : 'Reception Desk');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (ctx, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardGreenBorder,
                      width: 6,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.primaryShadow,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Booking Successful!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment has been secured.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              _TokenCard(
                patientName: displayName,
                token: _token,
                doctorName: docName,
                speciality: spec.toUpperCase(),
                waitTime: _waitTime,
                turnTime: _turnTime,
              ),
              const SizedBox(height: 18),
              if (notifyMe) _NotificationBanner(),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Go to Home',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'View Queue',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                  arguments: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TOKEN CARD ─────────────────────────────────────────────────────────────

class _TokenCard extends StatelessWidget {
  final String patientName;
  final String token;
  final String doctorName;
  final String speciality;
  final String waitTime;
  final String turnTime;

  const _TokenCard({
    required this.patientName,
    required this.token,
    required this.doctorName,
    required this.speciality,
    required this.waitTime,
    required this.turnTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardGreenBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E4F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'TOKEN NUMBER',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF584C8E),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patientName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your token number:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (rect) =>
                AppColors.primaryGradient.createShader(rect),
            child: Text(
              token,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            doctorName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            speciality,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardGreenBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR ESTIMATED TURN',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        turnTime,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'in $waitTime',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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

// ─── NOTIFICATION BANNER ─────────────────────────────────────────────────────

class _NotificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You will receive a push notification 2 tokens before your turn. Please arrive at the clinic on time.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
