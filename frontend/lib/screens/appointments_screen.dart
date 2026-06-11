import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/app_strings.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/booking_model.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';
import 'package:frontend/widgets/common/state_views.dart';

/// A single live booking the patient currently holds (view model).
class _Booking {
  final String id;
  final String token;
  final String doctor;
  final String specialty;
  final String hospital;
  DateTime date;
  String time;
  final String estWait;

  _Booking({
    required this.id,
    required this.token,
    required this.doctor,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.time,
    required this.estWait,
  });
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _tab = 0; // 0 = Upcoming, 1 = Past

  static const _slots = [
    '9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '2:00 PM', '2:30 PM', '3:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingsProvider>().load();
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmtWait(int? mins) {
    if (mins == null) return '';
    if (mins <= 0) return 'Now';
    if (mins < 60) return '~$mins mins';
    final h = (mins / 60).round();
    return '~$h hour${h > 1 ? 's' : ''}';
  }

  _Booking? _fromModel(BookingModel? b) {
    if (b == null) return null;
    final dt = b.expectedCallTime ??
        DateTime.tryParse(b.bookingDate) ??
        DateTime.now();
    return _Booking(
      id: b.id,
      token: b.tokenLabel,
      doctor: b.isReceptionToken
          ? (b.hospitalName.isNotEmpty ? b.hospitalName : 'Reception Desk')
          : b.doctorName,
      specialty: b.isReceptionToken ? 'Online Token' : b.appointmentType.label,
      hospital: b.hospitalName,
      date: dt,
      time: (b.preferredTime != null && b.preferredTime!.isNotEmpty)
          ? b.preferredTime!
          : (b.expectedCallTime != null
              ? DateFormat('h:mm a').format(b.expectedCallTime!)
              : '—'),
      estWait: _fmtWait(b.estimatedWaitMinutes),
    );
  }

  Future<void> _bookNow() async {
    await Navigator.pushNamed(context, '/book-appointment');
    if (!mounted) return;
    context.read<BookingsProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: AppStrings.appointments,
        showBack: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _SegTabs(
              tab: _tab,
              onChanged: (i) => setState(() => _tab = i),
              pastCount: bookings.past.length,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _tab == 0
                ? _buildUpcomingTab(bookings)
                : _buildPastTab(bookings),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab(BookingsProvider bookings) {
    if (bookings.loading && bookings.items.isEmpty) return const LoadingView();
    // Show every live booking — both a doctor appointment and an online token,
    // when the patient holds both — each as its own card.
    final actives = bookings.activeBookings;
    if (actives.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<BookingsProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
        children: [
          for (var i = 0; i < actives.length; i++) ...[
            if (i > 0) const SizedBox(height: 28),
            _buildBooked(_fromModel(actives[i])!),
          ],
        ],
      ),
    );
  }

  Widget _buildPastTab(BookingsProvider bookings) {
    if (bookings.loading && bookings.items.isEmpty) return const LoadingView();
    final past = bookings.past;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<BookingsProvider>().load(),
      child: past.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 90),
                Center(
                  child: Text('No past visits yet.',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary)),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              itemCount: past.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _PastRow(booking: past[i]),
            ),
    );
  }

  // ─── BOOKED STATE ─────────────────────────────────────────────────────────

  Widget _buildBooked(_Booking b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardGreenMedium,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CONFIRMED',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "You're booked!",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TokenHeroCard(booking: b),
          const SizedBox(height: 18),
          _DetailsCard(booking: b),
          const SizedBox(height: 18),
          // Notify reminder
          Container(
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
                    "We'll alert you 2 tokens before your turn. Please arrive on time.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Actions
          PrimaryButton(
            label: 'View Live Queue',
            icon: const Icon(Icons.timelapse_rounded,
                color: Colors.white, size: 18),
            onTap: () => Navigator.pushNamed(context, '/main', arguments: 1),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Reschedule / Postpone',
            icon: const Icon(Icons.event_repeat_rounded,
                color: AppColors.primary, size: 18),
            onTap: () => _showRescheduleSheet(b),
          ),
          const SizedBox(height: 10),
          _DangerButton(
            label: 'Cancel Booking',
            onTap: () => _showCancelSheet(b),
          ),
        ],
      ),
    );
  }

  // ─── NOT-BOOKED STATE ───────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Appointment',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You haven't booked a visit yet. Book an appointment and get your token instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Book Appointment',
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              onTap: _bookNow,
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESCHEDULE / POSTPONE ────────────────────────────────────────────────

  void _showRescheduleSheet(_Booking b) {
    // The appointment day is fixed — patients may only move to a different
    // time slot on the same day.
    final DateTime tempDate = b.date;
    String tempTime = _slots.contains(b.time) ? b.time : _slots.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reschedule Appointment',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a new time slot. The appointment day stays the same.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardGreenBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateUtils.isSameDay(tempDate, DateTime.now())
                            ? 'Today, ${DateFormat('d MMM').format(tempDate)}'
                            : DateFormat('EEE, d MMM').format(tempDate),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'TIME SLOT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((s) {
                    final selected = s == tempTime;
                    return GestureDetector(
                      onTap: () => setSheet(() => tempTime = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFEEEAF6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color:
                                selected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Confirm New Time',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final updated = await context
                        .read<BookingsProvider>()
                        .reschedule(
                          b.id,
                          DateFormat('yyyy-MM-dd').format(tempDate),
                          time: tempTime,
                        );
                    if (!mounted) return;
                    _snack(
                      updated != null
                          ? 'Rescheduled to $tempTime — new token #${updated.tokenNumber}.'
                          : 'Could not reschedule. Please try again.',
                      error: updated == null,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── CANCEL / DISCARD ─────────────────────────────────────────────────────

  void _showCancelSheet(_Booking b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Cancel this booking?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Token #${b.token} with ${b.doctor} will be released. You can always book again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Keep it',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok =
                          await context.read<BookingsProvider>().cancel(b.id);
                      if (!mounted) return;
                      _snack(ok ? 'Booking cancelled.' : 'Could not cancel.',
                          error: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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

// ─── TOKEN HERO CARD ────────────────────────────────────────────────────────

class _TokenHeroCard extends StatelessWidget {
  final _Booking booking;
  const _TokenHeroCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        children: [
          Text(
            'YOUR TOKEN NUMBER',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.token,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 58,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            booking.doctor,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            booking.specialty,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _heroStat(
                    Icons.calendar_today_rounded,
                    'DATE',
                    DateUtils.isSameDay(booking.date, DateTime.now())
                        ? 'Today'
                        : DateFormat('d MMM').format(booking.date),
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _heroStat(
                    Icons.access_time_rounded,
                    'TIME',
                    booking.time,
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _heroStat(
                    Icons.hourglass_bottom_rounded,
                    'EST. WAIT',
                    booking.estWait,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── DETAILS CARD ─────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final _Booking booking;
  const _DetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(Icons.local_hospital_outlined, 'Hospital', booking.hospital),
          const Divider(height: 22, color: AppColors.divider),
          _row(Icons.medical_services_outlined, 'Department',
              booking.specialty),
          const Divider(height: 22, color: AppColors.divider),
          _row(
            Icons.event_rounded,
            'Date & Time',
            '${DateFormat('EEE, d MMM').format(booking.date)} · ${booking.time}',
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cardGreenLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── DANGER BUTTON ─────────────────────────────────────────────────────────

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SEGMENTED TABS (Upcoming / Past) ──────────────────────────────────────

class _SegTabs extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;
  final int pastCount;
  const _SegTabs({
    required this.tab,
    required this.onChanged,
    required this.pastCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _seg('Upcoming', 0),
          _seg(pastCount > 0 ? 'Past ($pastCount)' : 'Past', 1),
        ],
      ),
    );
  }

  Widget _seg(String label, int i) {
    final selected = tab == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PAST VISIT ROW ────────────────────────────────────────────────────────

class _PastRow extends StatelessWidget {
  final BookingModel booking;
  const _PastRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final served = booking.status == 'served';
    final statusLabel = served
        ? 'Served'
        : (booking.status == 'cancelled' ? 'Cancelled' : 'No-show');
    final statusColor = served ? AppColors.success : AppColors.error;
    final dateStr = DateFormat('d MMM y').format(
        DateTime.tryParse(booking.bookingDate) ??
            booking.servedAt ??
            DateTime.now());

    return Container(
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
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(booking.tokenLabel,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        booking.doctorName.isEmpty
                            ? 'Consultation'
                            : booking.doctorName,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      [booking.hospitalName, dateStr]
                          .where((s) => s.isNotEmpty)
                          .join('  ·  '),
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor)),
              ),
            ],
          ),
          if ((booking.diagnosis ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DOCTOR'S NOTES",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Text(booking.diagnosis!,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
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
}
