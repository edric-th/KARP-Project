import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/booking_model.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/queue_provider.dart';

class QueueScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const QueueScreen({super.key, this.onMenuTap});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String? _trackingDoctorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsProvider>().load();
    });
  }

  /// Keep the polling QueueProvider pointed at the active booking's doctor.
  void _syncTracking(BookingModel? active) {
    if (active != null && active.doctorId != _trackingDoctorId) {
      _trackingDoctorId = active.doctorId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .read<QueueProvider>()
              .start(active.doctorId, date: active.bookingDate);
        }
      });
    } else if (active == null && _trackingDoctorId != null) {
      _trackingDoctorId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<QueueProvider>().stop();
      });
    }
  }

  Future<void> _refresh() async {
    // Capture providers before awaiting so we never touch `context` across the
    // async gap (use_build_context_synchronously).
    final bookings = context.read<BookingsProvider>();
    final queue = context.read<QueueProvider>();
    await bookings.load();
    await queue.refreshNow();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsProvider>();
    final queue = context.watch<QueueProvider>();
    final active = bookings.activeBooking;
    _syncTracking(active);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _Header(
            onMenuTap: widget.onMenuTap,
            onBellTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  if (bookings.loading && bookings.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  else if (active == null)
                    _buildEmpty()
                  else
                    ..._buildActive(active, queue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActive(BookingModel active, QueueProvider queue) {
    final status = queue.status;
    final myEntry = status?.entryFor(active.id);
    final position = myEntry?.position ?? active.position ?? 0;
    final eta = myEntry?.estimatedWaitMinutes ?? active.estimatedWaitMinutes ?? 0;
    final nowServing = status?.nowServing;
    final waiting = status?.waiting ?? const <BookingModel>[];

    // "People ahead" should read 0 when you're first in line with nobody yet
    // being served (so we don't show a misleading "000" now-serving token).
    final noOneServing = nowServing == null;
    final isNext = !active.isActive && noOneServing && position <= 1;
    final peopleAhead = active.isActive
        ? 0
        : (noOneServing ? (position - 1).clamp(0, 9999) : position);

    return [
      _TokenHero(
        myToken: active.tokenLabel,
        doctor: active.doctorName,
        hospital: active.hospitalName,
        peopleAhead: peopleAhead,
        etaMinutes: eta,
        nowServingToken: nowServing?.tokenNumber,
        isBeingServed: active.isActive,
        isNext: isNext,
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Text('Up Next',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (queue.loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (waiting.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No one else is waiting right now.',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        )
      else
        ...waiting.take(8).map((b) => _WaitingRow(
              booking: b,
              isMine: b.id == active.id,
            )),
    ];
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.hourglass_empty_rounded,
                color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 20),
          const Text("You're not in a queue",
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Book an appointment to get a live token and\ntrack your turn in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/book-appointment'),
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: const Text('Book an Appointment'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/online-token'),
            icon: const Icon(Icons.confirmation_number_outlined, size: 18),
            label: const Text('Or just get an online token'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback onBellTap;
  const _Header({this.onMenuTap, required this.onBellTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed:
                    onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
              ),
              const Expanded(
                child: Text('Live Queue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: onBellTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TOKEN HERO ──────────────────────────────────────────────────────────────

class _TokenHero extends StatelessWidget {
  final String myToken;
  final String doctor;
  final String hospital;
  final int peopleAhead;
  final int etaMinutes;
  final int? nowServingToken;
  final bool isBeingServed;

  /// True when the patient is first in line and nobody is being served yet —
  /// instead of a meaningless "000" we reassure them the doctor is calling soon.
  final bool isNext;

  const _TokenHero({
    required this.myToken,
    required this.doctor,
    required this.hospital,
    required this.peopleAhead,
    required this.etaMinutes,
    required this.nowServingToken,
    required this.isBeingServed,
    this.isNext = false,
  });

  String get _etaLabel {
    if (isBeingServed) return "It's your turn";
    if (isNext) return 'Get ready — the doctor will call you within ~5 min';
    if (etaMinutes <= 0) return 'Almost your turn';
    if (etaMinutes < 60) return '~$etaMinutes min away';
    final h = (etaMinutes / 60).round();
    return '~$h hour${h > 1 ? 's' : ''} away';
  }

  String get _nowServingValue {
    if (nowServingToken != null) {
      return nowServingToken.toString().padLeft(3, '0');
    }
    return isNext ? 'Soon' : '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isBeingServed ? 'IN CONSULTATION' : 'WAITING',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8)),
              ),
              const Spacer(),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(doctor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    if (hospital.isNotEmpty)
                      Text(hospital,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('YOUR TOKEN',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.75))),
          Text(myToken,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(_etaLabel,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                    label: 'NOW SERVING', value: _nowServingValue),
              ),
              Expanded(
                child: _HeroStat(
                    label: 'PEOPLE AHEAD', value: '$peopleAhead'),
              ),
              Expanded(
                child: _HeroStat(
                    label: 'EST. WAIT',
                    value: etaMinutes <= 0 ? 'Now' : '${etaMinutes}m'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      );
}

// ─── WAITING ROW ─────────────────────────────────────────────────────────────

class _WaitingRow extends StatelessWidget {
  final BookingModel booking;
  final bool isMine;
  const _WaitingRow({required this.booking, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final eta = booking.estimatedWaitMinutes;
    final etaLabel = eta == null
        ? ''
        : (eta <= 0 ? 'Now' : (eta < 60 ? '$eta min' : '~${(eta / 60).round()}h'));
    final callAt = booking.expectedCallTime;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine ? AppColors.cardGreenLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isMine ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(booking.tokenLabel,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isMine ? Colors.white : AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMine ? 'You' : 'Token ${booking.tokenLabel}',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Position ${booking.position ?? '-'}',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (etaLabel.isNotEmpty)
                Text(etaLabel,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              if (callAt != null)
                Text(DateFormat('h:mm a').format(callAt),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
