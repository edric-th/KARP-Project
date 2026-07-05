import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/booking_model.dart';
import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/queue_provider.dart';
import 'package:frontend/utils/profile_gate.dart';

class QueueScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const QueueScreen({super.key, this.onMenuTap});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  Set<String> _trackingKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsProvider>().load();
      // Ensure the doctor catalog is available so we can label a closed doctor's
      // working days on the live-queue card (load() is a no-op once cached).
      context.read<CatalogProvider>().load();
    });
  }

  /// Track every live booking's queue at once — the doctor's queue for an
  /// appointment and the hospital reception desk for an online token — so both
  /// can be shown side by side and each polls the correct endpoint.
  void _syncTracking(List<BookingModel> actives) {
    final targets = actives.map(_targetFor).toList();
    final keys = targets.map((t) => t.key).toSet();
    if (keys.length == _trackingKeys.length &&
        _trackingKeys.containsAll(keys)) {
      return;
    }
    _trackingKeys = keys;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QueueProvider>().sync(targets);
    });
  }

  QueueTarget _targetFor(BookingModel b) {
    final reception = b.isReceptionToken;
    final id = reception ? b.hospitalId : b.doctorId;
    final key =
        reception ? QueueTarget.receptionKey(id) : QueueTarget.doctorKey(id);
    return QueueTarget(key, id, reception, b.bookingDate);
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
    final appt = bookings.activeAppointment;
    final token = bookings.activeReceptionToken;
    final actives = [?appt, ?token];
    _syncTracking(actives);

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
                  else if (actives.isEmpty)
                    _buildEmpty()
                  else ...[
                    ..._buildSection(appt, 'Doctor Appointment', queue),
                    ..._buildSection(token, 'Online Token', queue),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Resolve the live snapshot for [active] and render its section, or nothing
  /// when the patient holds no booking of that kind.
  List<Widget> _buildSection(
      BookingModel? active, String title, QueueProvider queue) {
    if (active == null) return const [];
    final key = active.isReceptionToken
        ? QueueTarget.receptionKey(active.hospitalId)
        : QueueTarget.doctorKey(active.doctorId);
    return _buildActive(
        active, queue.statusFor(key), title, queue.isLoading(key));
  }

  List<Widget> _buildActive(BookingModel active, QueueStatusModel? status,
      String title, bool loading) {
    // Parked by the doctor (e.g. sent for an X-ray): the patient is out of the
    // live queue until they signal they're back, so show a dedicated card
    // instead of the token/ETA hero.
    if (active.isOnHold) {
      return [
        _SectionTitle(title),
        const SizedBox(height: 12),
        _OnHoldCard(
          doctor:
              active.isReceptionToken ? 'Reception Desk' : active.doctorName,
          myToken: active.tokenLabel,
          holdReason: active.holdReason,
          returned: active.returned,
          onImBack: () =>
              context.read<BookingsProvider>().notifyReturn(active.id),
        ),
        const SizedBox(height: 28),
      ];
    }

    final myEntry = status?.entryFor(active.id);
    final position = myEntry?.position ?? active.position ?? 0;
    final eta = myEntry?.estimatedWaitMinutes ?? active.estimatedWaitMinutes ?? 0;
    final nowServing = status?.nowServing;
    final waiting = status?.waiting ?? const <BookingModel>[];

    // Whether the doctor is open right now. Reception tokens are always "open"
    // (the desk has no schedule); only doctor appointments can be closed.
    final available =
        active.isReceptionToken ? true : (status?.doctorAvailableNow ?? true);
    final daysLabel = active.isReceptionToken
        ? ''
        : (context.read<CatalogProvider>().doctorById(active.doctorId)?.availabilityDaysLabel ?? '');

    // "People ahead" should read 0 when you're first in line with nobody yet
    // being served (so we don't show a misleading "000" now-serving token).
    final noOneServing = nowServing == null;
    // Only treat the patient as "next" when the doctor is actually open — when
    // closed we want the availability message, not "the doctor will call you
    // within ~5 min".
    final isNext = available && !active.isActive && noOneServing && position <= 1;
    final peopleAhead = active.isActive
        ? 0
        : (noOneServing ? (position - 1).clamp(0, 9999) : position);

    return [
      _SectionTitle(title),
      const SizedBox(height: 12),
      _TokenHero(
        myToken: active.tokenLabel,
        doctor: active.isReceptionToken ? 'Reception Desk' : active.doctorName,
        hospital: active.hospitalName,
        peopleAhead: peopleAhead,
        etaMinutes: eta,
        nowServingToken: nowServing?.tokenNumber,
        isBeingServed: active.isActive,
        isNext: isNext,
        isReception: active.isReceptionToken,
        doctorAvailableNow: available,
        availabilityDaysLabel: daysLabel,
        expectedCallTime: active.expectedCallTime,
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
          if (loading)
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
      const SizedBox(height: 28),
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
            onPressed: () async {
              if (await ensureProfileComplete(context) && mounted) {
                Navigator.pushNamed(context, '/book-appointment');
              }
            },
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

// ─── SECTION TITLE ───────────────────────────────────────────────────────────

/// Heading above each queue block so the patient can tell their doctor
/// appointment apart from their online token when both are live.
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary));
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
  /// instead of a meaningless "000" we reassure them they'll be called soon.
  final bool isNext;

  /// True for an online (reception-desk) token — there is no doctor, so the
  /// "you're next" copy talks about the token being called, not the doctor.
  final bool isReception;

  /// False when the doctor is currently closed — drives the availability-based
  /// turn-time copy instead of the near-term "~5 min" message.
  final bool doctorAvailableNow;

  /// e.g. "Mon–Fri" — the doctor's working days, shown when they're closed.
  final String availabilityDaysLabel;

  /// The booking's expected call time (availability-anchored by the backend),
  /// used to show a real day + clock time when the doctor is closed.
  final DateTime? expectedCallTime;

  const _TokenHero({
    required this.myToken,
    required this.doctor,
    required this.hospital,
    required this.peopleAhead,
    required this.etaMinutes,
    required this.nowServingToken,
    required this.isBeingServed,
    this.isNext = false,
    this.isReception = false,
    this.doctorAvailableNow = true,
    this.availabilityDaysLabel = '',
    this.expectedCallTime,
  });

  /// True only when we should surface the doctor's next-availability turn time
  /// (closed doctor, real appointment) rather than a live minute estimate.
  bool get _showsAvailability => !isReception && !doctorAvailableNow;

  String get _etaLabel {
    if (isBeingServed) return "It's your turn";
    if (_showsAvailability) {
      final t = expectedCallTime;
      final days = availabilityDaysLabel.isNotEmpty
          ? 'Available $availabilityDaysLabel'
          : 'Doctor is currently off';
      if (t != null) {
        return '$days · your turn ~${DateFormat('EEE h:mm a').format(t.toLocal())}';
      }
      return days;
    }
    if (isNext) {
      return isReception
          ? 'Get ready — your token will be called within 2-3 min'
          : 'Get ready — the doctor will call you within ~5 min';
    }
    if (etaMinutes <= 0) return 'Almost your turn';
    if (etaMinutes < 60) return '~$etaMinutes min away';
    final h = (etaMinutes / 60).round();
    return '~$h hour${h > 1 ? 's' : ''} away';
  }

  String get _nowServingValue {
    if (nowServingToken != null) {
      return nowServingToken.toString().padLeft(3, '0');
    }
    // While the doctor is closed nobody is being served and there's no "soon".
    if (_showsAvailability) return '—';
    return isNext ? 'Soon' : '—';
  }

  /// The "EST. WAIT" figure: a clock time when the doctor is closed (a minute
  /// count would read as a huge, confusing number), else a compact duration.
  String get _estWaitValue {
    if (_showsAvailability) {
      final t = expectedCallTime;
      return t != null ? DateFormat('h:mm a').format(t.toLocal()) : '—';
    }
    if (etaMinutes <= 0) return 'Now';
    if (etaMinutes < 60) return '${etaMinutes}m';
    final h = (etaMinutes / 60).round();
    return '${h}h';
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
                child: _HeroStat(label: 'EST. WAIT', value: _estWaitValue),
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

// ─── ON-HOLD CARD ────────────────────────────────────────────────────────────

/// Shown when the doctor has parked the patient mid-visit (e.g. sent for an
/// X-ray). Lets them tap "I'm back with my report" so the doctor can call them
/// in again; once tapped it waits for the call-back.
class _OnHoldCard extends StatefulWidget {
  final String doctor;
  final String myToken;
  final String holdReason;
  final bool returned;
  final Future<bool> Function() onImBack;

  const _OnHoldCard({
    required this.doctor,
    required this.myToken,
    required this.holdReason,
    required this.returned,
    required this.onImBack,
  });

  @override
  State<_OnHoldCard> createState() => _OnHoldCardState();
}

class _OnHoldCardState extends State<_OnHoldCard> {
  bool _busy = false;

  Future<void> _tap() async {
    setState(() => _busy = true);
    final ok = await widget.onImBack();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not notify the doctor. Please try again.')),
      );
    }
  }

  static const _amber = Color(0xFFF59E0B);
  static const _amberDark = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final returned = widget.returned;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_amber, _amberDark],
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ON HOLD',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8)),
              ),
              const Spacer(),
              Flexible(
                child: Text(widget.doctor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
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
          Text(widget.myToken,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(
            returned
                ? "The doctor has been notified you're back"
                : 'The doctor paused your turn for now',
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          if (widget.holdReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Reason: ${widget.holdReason}',
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 13, color: Colors.white)),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: returned
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('Waiting to be called back…',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  )
                : FilledButton.icon(
                    onPressed: _busy ? null : _tap,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _amberDark))
                        : const Icon(Icons.assignment_turned_in_rounded),
                    label: Text(_busy ? 'Notifying…' : "I'm back with my report"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _amberDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
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
