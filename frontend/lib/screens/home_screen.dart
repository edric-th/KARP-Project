import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/app_strings.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/booking_model.dart';
import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/queue_provider.dart';
import 'package:frontend/widgets/common/custom_input_field.dart';
import 'package:frontend/widgets/common/state_views.dart';
import 'package:frontend/widgets/home/doctor_card.dart';
import 'package:frontend/widgets/home/hospital_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const HomeScreen({super.key, this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _trackingKeys = {};
  Timer? _pollTimer;
  bool _profilePromptDismissed = false;

  bool _needsProfile(AuthProvider auth) {
    if (_profilePromptDismissed) return false;
    final p = auth.profile;
    if (p == null) return false;
    return p.bloodGroup.isEmpty || p.dateOfBirth.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().load();
      context.read<BookingsProvider>().load();
    });
    // Keep the booking list fresh so the queue card reflects served/advanced
    // tokens without a manual pull-to-refresh (the QueueProvider polls too).
    // Kept modest to limit Firestore reads — the server caches queue queries.
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) context.read<BookingsProvider>().load();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Keep the polling QueueProvider pointed at the patient's live bookings — the
  /// doctor's queue for an appointment AND the hospital reception desk for an
  /// online token, tracked side by side — so each queue's live "ahead of you"
  /// count, ETA and now-serving token stay accurate without a refresh.
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
    final catalog = context.read<CatalogProvider>();
    final bookings = context.read<BookingsProvider>();
    final queue = context.read<QueueProvider>();
    await Future.wait([catalog.load(force: true), bookings.load()]);
    await queue.refreshNow();
  }

  /// Build the home hero card from the patient's booking + the LIVE queue
  /// snapshot (real people-ahead + ETA), falling back to the booking's own
  /// fields before the queue has loaded.
  QueueModel? _activeQueueModel(BookingModel? b, QueueStatusModel? status) {
    if (b == null) return null;
    final entry = status?.entryFor(b.id);
    final ahead = entry?.position ?? b.position ?? 0;
    final eta = entry?.estimatedWaitMinutes ?? b.estimatedWaitMinutes ?? 0;
    final token = b.tokenNumber;
    // Prefer the real now-serving token from the live snapshot; fall back to
    // deriving it from your token minus the people ahead of you.
    final serving = status?.nowServing?.tokenNumber;
    final current = serving ?? (token - ahead).clamp(0, token);
    // Reception tokens are always "open"; only doctor appointments can be closed.
    final available =
        b.isReceptionToken ? true : (status?.doctorAvailableNow ?? true);
    final daysLabel = b.isReceptionToken
        ? ''
        : (context.read<CatalogProvider>().doctorById(b.doctorId)?.availabilityDaysLabel ?? '');
    return QueueModel(
      id: b.id,
      hospitalName: b.hospitalName,
      doctorName: b.isReceptionToken ? 'Reception Desk' : b.doctorName,
      specialty: b.isReceptionToken ? 'Online Token' : '',
      queueNumber: token,
      currentNumber: current,
      totalAhead: ahead,
      estimatedMinutes: eta,
      status: b.isActive ? QueueStatus.active : QueueStatus.waiting,
      department: b.hospitalName,
      doctorAvailableNow: available,
      availabilityDaysLabel: daysLabel,
      expectedCallTime: b.expectedCallTime,
    );
  }

  /// A labelled live-queue block (now-serving hero + queue list) for one of the
  /// patient's bookings, or nothing when that queue isn't active.
  List<Widget> _buildQueueSection(String title, QueueModel? q) {
    if (q == null) return const [];
    return [
      const SizedBox(height: 18),
      _QueueSectionHeader(title),
      const SizedBox(height: 10),
      _NowServingCard(queue: q),
      const SizedBox(height: 24),
      _LiveQueueStatus(queue: q),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final bookings = context.watch<BookingsProvider>();
    final queue = context.watch<QueueProvider>();

    final appt = bookings.activeAppointment;
    final token = bookings.activeReceptionToken;
    _syncTracking([?appt, ?token]);

    final firstName = (auth.profile?.displayName ?? 'there').split(' ').first;
    final apptQueue = appt == null
        ? null
        : _activeQueueModel(
            appt, queue.statusFor(QueueTarget.doctorKey(appt.doctorId)));
    final tokenQueue = token == null
        ? null
        : _activeQueueModel(
            token, queue.statusFor(QueueTarget.receptionKey(token.hospitalId)));
    final activeQueue = apptQueue ?? tokenQueue;
    final hospitals = catalog.hospitals.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _GreetingBlock(firstName: firstName, activeQueue: activeQueue),
            if (_needsProfile(auth)) ...[
              const SizedBox(height: 16),
              _CompleteProfileBanner(
                onTap: () =>
                    Navigator.pushNamed(context, '/complete-profile'),
                onDismiss: () =>
                    setState(() => _profilePromptDismissed = true),
              ),
            ],
            ..._buildQueueSection('Doctor Appointment', apptQueue),
            ..._buildQueueSection('Online Token', tokenQueue),
            const SizedBox(height: 24),
            SearchField(
              hint: 'Search hospitals, doctors...',
              onChanged: (q) {
                if (q.isNotEmpty) {
                  Navigator.pushNamed(context, '/doctors');
                }
              },
            ),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 14),
            _OnlineTokenBanner(
              onTap: () => Navigator.pushNamed(context, '/online-token'),
            ),
            const SizedBox(height: 28),
            _buildSectionHeader(
              context,
              'Nearby Hospitals',
              onSeeAll: () => Navigator.pushNamed(context, '/hospitals'),
            ),
            const SizedBox(height: 14),
            ..._buildHospitals(catalog, hospitals),
            const SizedBox(height: 28),
            _buildSectionHeader(
              context,
              'Top Doctors',
              onSeeAll: () => Navigator.pushNamed(context, '/doctors'),
            ),
            const SizedBox(height: 14),
            _buildDoctors(catalog),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHospitals(
      CatalogProvider catalog, List<HospitalModel> hospitals) {
    if (catalog.loading && catalog.hospitals.isEmpty) {
      return const [
        SizedBox(height: 120, child: LoadingView()),
      ];
    }
    if (hospitals.isEmpty) {
      return [_hint(catalog.error ?? 'No hospitals available yet.')];
    }
    return hospitals
        .map((h) => HospitalCard(
              hospital: h,
              onTap: () => Navigator.pushNamed(context, '/hospital-detail',
                  arguments: h),
            ))
        .toList();
  }

  Widget _buildDoctors(CatalogProvider catalog) {
    if (catalog.loading && catalog.doctors.isEmpty) {
      return const SizedBox(height: 210, child: LoadingView());
    }
    if (catalog.doctors.isEmpty) {
      return _hint(catalog.error ?? 'No doctors available yet.');
    }
    final doctors = catalog.doctors;
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => DoctorCard(
          doctor: doctors[i],
          onTap: () => Navigator.pushNamed(context, '/doctor-detail',
              arguments: doctors[i]),
        ),
      ),
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary)),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
        onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
      ),
      title: const Text(
        'MeroPalo Care',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.local_hospital_rounded,
            label: 'Join Queue',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/hospitals'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_today_rounded,
            label: 'Book Appt.',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/book-appointment'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_search_rounded,
            label: 'Doctors',
            color: AppColors.primary,
            onTap: () => Navigator.pushNamed(context, '/doctors'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required VoidCallback onSeeAll,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            AppStrings.viewAll,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── QUEUE SECTION HEADER ────────────────────────────────────────────────────

/// A small heading shown above each live-queue block so the patient can tell
/// their doctor-appointment queue apart from their online-token queue.
class _QueueSectionHeader extends StatelessWidget {
  final String title;
  const _QueueSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─── ONLINE TOKEN BANNER ─────────────────────────────────────────────────────

class _OnlineTokenBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OnlineTokenBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.confirmation_number_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get Online Token',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reserve your number now • pay at reception',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── GREETING ────────────────────────────────────────────────────────────────

class _GreetingBlock extends StatelessWidget {
  final String firstName;
  final QueueModel? activeQueue;

  const _GreetingBlock({required this.firstName, required this.activeQueue});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $firstName 👋',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        if (activeQueue != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  activeQueue!.hospitalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, size: 4, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Token ${activeQueue!.queueNumber.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── NOW SERVING CARD ────────────────────────────────────────────────────────

class _NowServingCard extends StatelessWidget {
  final QueueModel queue;
  const _NowServingCard({required this.queue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _PulseDot(),
                    SizedBox(width: 6),
                    Text(
                      'NOW SERVING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    queue.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    queue.specialty.isNotEmpty
                        ? queue.specialty
                        : 'General Consultation',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            queue.currentNumber.toString().padLeft(3, '0'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NowStat(
                  label: 'YOUR TOKEN',
                  value: queue.queueNumber.toString().padLeft(3, '0'),
                ),
              ),
              Expanded(
                child: _NowStat(
                  label: queue.doctorAvailableNow ? 'WAITING TIME' : 'YOUR TURN',
                  value: !queue.doctorAvailableNow && queue.expectedCallTime != null
                      ? DateFormat('EEE h:mm a').format(queue.expectedCallTime!.toLocal())
                      : '~${queue.estimatedMinutes} min',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NowStat extends StatelessWidget {
  final String label;
  final String value;
  const _NowStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── LIVE QUEUE STATUS ───────────────────────────────────────────────────────

class _LiveQueueStatus extends StatelessWidget {
  final QueueModel queue;
  const _LiveQueueStatus({required this.queue});

  List<_TokenEntry> get _tokens {
    final entries = <_TokenEntry>[];
    final current = queue.currentNumber;
    final yours = queue.queueNumber;
    final ahead = queue.totalAhead;
    final perPerson = ahead > 0 ? queue.estimatedMinutes / ahead : 0.0;

    // Only render people who are genuinely ahead of you: the patient currently
    // in consult plus anyone still waiting. When nobody is ahead, the card
    // shows only your token — no phantom "already served" rows.
    if (ahead > 0) {
      entries.add(
        _TokenEntry(
          number: current,
          state: _TokenState.inConsult,
          tag: _statusFor(current),
          etaMinutes: 0,
        ),
      );
      for (var i = 1; i < ahead; i++) {
        final t = current + i;
        entries.add(
          _TokenEntry(
            number: t,
            state: _TokenState.waiting,
            tag: _statusFor(t),
            etaMinutes: (perPerson * i).round(),
          ),
        );
      }
    }

    entries.add(
      _TokenEntry(
        number: yours,
        state: _TokenState.you,
        tag: 'NEW PATIENT',
        etaMinutes: queue.estimatedMinutes,
      ),
    );

    return entries;
  }

  String _statusFor(int token) {
    switch (token % 3) {
      case 0:
        return 'NEW PATIENT';
      case 1:
        return 'FOLLOW UP';
      default:
        return 'REPORT SHOWING';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Doctor is closed: a synthetic minute-by-minute breakdown would show
    // misleading huge numbers. Show the real availability + turn time instead.
    if (!queue.doctorAvailableNow) {
      return _ClosedDoctorNotice(queue: queue);
    }
    final tokens = _tokens;
    final ahead = queue.totalAhead;
    final badgeText = ahead <= 0 ? "It's your turn" : '$ahead ahead of you';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live Queue Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...tokens.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QueueRow(entry: t),
          ),
        ),
      ],
    );
  }
}

/// Shown on the home live-queue card when the booked doctor is currently closed
/// — surfaces the real availability days and the patient's anchored turn time
/// instead of a meaningless minute-by-minute breakdown.
class _ClosedDoctorNotice extends StatelessWidget {
  final QueueModel queue;
  const _ClosedDoctorNotice({required this.queue});

  @override
  Widget build(BuildContext context) {
    final t = queue.expectedCallTime;
    final turn = t != null ? DateFormat('EEE, MMM d · h:mm a').format(t.toLocal()) : null;
    final days = queue.availabilityDaysLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Queue Status',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      days.isNotEmpty
                          ? '${queue.doctorName} is available $days'
                          : '${queue.doctorName} is currently off duty',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      turn != null
                          ? 'You are token #${queue.queueNumber.toString().padLeft(3, '0')} — your turn is around $turn.'
                          : 'You are token #${queue.queueNumber.toString().padLeft(3, '0')}. You\'ll be called when the doctor is next available.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TokenState { inConsult, waiting, you }

class _TokenEntry {
  final int number;
  final _TokenState state;
  final String tag;
  final int etaMinutes;

  const _TokenEntry({
    required this.number,
    required this.state,
    required this.tag,
    required this.etaMinutes,
  });
}

class _QueueRow extends StatelessWidget {
  final _TokenEntry entry;
  const _QueueRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    switch (entry.state) {
      case _TokenState.inConsult:
        return _ActiveRow(entry: entry);
      case _TokenState.you:
        return _YouRow(entry: entry);
      case _TokenState.waiting:
        return _WaitingRow(entry: entry);
    }
  }
}

class _ActiveRow extends StatelessWidget {
  final _TokenEntry entry;
  const _ActiveRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.info, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              entry.number.toString().padLeft(3, '0'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'IN CONSULT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: _TagChip(label: entry.tag, dark: true)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '20 min',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.medical_services_outlined,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  final _TokenEntry entry;
  const _WaitingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              entry.number.toString().padLeft(3, '0'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _TagChip(label: 'WAITING', tone: _ChipTone.warning),
                const SizedBox(width: 8),
                Flexible(child: _TagChip(label: entry.tag)),
              ],
            ),
          ),
          Text(
            '~${entry.etaMinutes} min',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _YouRow extends StatelessWidget {
  final _TokenEntry entry;
  const _YouRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary, width: 1.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              entry.number.toString().padLeft(3, '0'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.divider),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'YOU',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: _TagChip(label: entry.tag)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Next in line',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.circle,
                      size: 4,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.etaMinutes} min',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { neutral, warning, success, info }

class _TagChip extends StatelessWidget {
  final String label;
  final _ChipTone tone;
  final bool dark;

  const _TagChip({
    required this.label,
    this.tone = _ChipTone.neutral,
    this.dark = false,
  });

  Color get _bg {
    if (dark) return Colors.white.withValues(alpha: 0.18);
    switch (tone) {
      case _ChipTone.warning:
        return const Color(0xFFFDE9C7);
      case _ChipTone.success:
        return AppColors.cardGreenLight;
      case _ChipTone.info:
        return const Color(0xFFDDE9FF);
      case _ChipTone.neutral:
        return Colors.white;
    }
  }

  Color get _fg {
    if (dark) return Colors.white;
    switch (tone) {
      case _ChipTone.warning:
        return const Color(0xFF9A6A0E);
      case _ChipTone.success:
        return AppColors.primary;
      case _ChipTone.info:
        return AppColors.info;
      case _ChipTone.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: tone == _ChipTone.neutral && !dark
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── QUICK ACTION ────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMPLETE PROFILE BANNER ───────────────────────────────────────────────

class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _CompleteProfileBanner({required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.cardGreenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardGreenBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_ind_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete your profile',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 2),
                  Text('Add your medical & emergency details',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
