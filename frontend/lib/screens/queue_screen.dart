import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

class QueueScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const QueueScreen({super.key, this.onMenuTap});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _tab = 0; // 0 = Active, 1 = History
  int _dateFilter = 0; // 0 = This Month, 1 = Last 3 Months, 2 = All Time

  // ─── Patient's active queue context ───────────────────────────────────
  static const _myDepartment = 'Cardiology Department';
  static const _myWing = 'Main Clinic Wing';
  static const _myDoctor = 'Dr. Sharma';
  static const _myRoom = 'Room 101';
  static const _myToken = '047';
  static const _currentToken = '042';
  static const _ahead = 5;
  static const _minutesAway = 18;

  // Same department, different specialists / supporting staff
  static const _departmentTeam = [
    _TeamMember(
      name: 'Dr. Sharma',
      role: 'Consulting Cardiologist',
      room: 'Room 101',
      isPrimary: true,
    ),
    _TeamMember(
      name: 'Dr. Maharjan',
      role: 'Cardiology Resident',
      room: 'Room 102',
      isPrimary: false,
    ),
    _TeamMember(
      name: 'Nurse Anjali',
      role: 'ECG Nurse',
      room: 'Room 103',
      isPrimary: false,
    ),
  ];

  // Up next in the SAME department / same doctor
  static const _upNextSameDept = [
    _UpNext(token: '048', queueType: 'General Queue', delta: '+22 min'),
    _UpNext(token: '049', queueType: 'Priority Queue', delta: '+30 min'),
    _UpNext(token: '050', queueType: 'General Queue', delta: '+38 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _TopHeader(
            onMenuTap: widget.onMenuTap,
            onBellTap: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              child: _tab == 0 ? _buildActive() : _buildHistory(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVE TAB ─────────────────────────────────────────────────────────

  Widget _buildActive() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LiveQueueTrackerBar(room: _myRoom, time: _currentTimeLabel()),
        const SizedBox(height: 18),
        _ActiveHistoryToggle(
          current: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 22),
        _TokenHeroCard(
          tokenNumber: _myToken,
          minutesAway: _minutesAway,
          department: _myDepartment,
          doctor: _myDoctor,
          wing: _myWing,
          current: _currentToken,
          ahead: _ahead.toString().padLeft(2, '0'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _SectionLabel('YOUR DEPARTMENT TEAM'),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  _snack('Opening $_myDepartment directory'),
              child: Text(
                'View Directory',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._departmentTeam.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DoctorStatusRow(member: m),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _SectionLabel('UP NEXT IN ${_myDepartment.toUpperCase()}'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tokens ahead being seen by $_myDoctor',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._upNextSameDept.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _UpNextTile(
              token: u.token,
              queueType: u.queueType,
              doctor: _myDoctor,
              delta: u.delta,
            ),
          ),
        ),
      ],
    );
  }

  // ─── HISTORY TAB ────────────────────────────────────────────────────────

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PatientHistoryHeader(
          toggle: _ActiveHistoryToggle(
            current: _tab,
            onChanged: (i) => setState(() => _tab = i),
            invert: true,
          ),
        ),
        const SizedBox(height: 22),
        _DateFilterChips(
          current: _dateFilter,
          onChanged: (i) => setState(() => _dateFilter = i),
        ),
        const SizedBox(height: 18),
        _VisitHistoryCard(),
        const SizedBox(height: 18),
        _YourPastTokensCard(),
      ],
    );
  }

  String _currentTimeLabel() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final mins = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$mins $period';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── TOP HEADER ─────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback onBellTap;
  const _TopHeader({required this.onMenuTap, required this.onBellTap});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 14),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Live Queue',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onBellTap,
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIVE TRACKER BAR (ACTIVE) ──────────────────────────────────────────────

class _LiveQueueTrackerBar extends StatelessWidget {
  final String room;
  final String time;
  const _LiveQueueTrackerBar({required this.room, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live Queue Tracker',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              '$room • $time',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PATIENT HISTORY HEADER (replaces admin "Queue Operations Active") ──────

class _PatientHistoryHeader extends StatelessWidget {
  final Widget toggle;
  const _PatientHistoryHeader({required this.toggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Queue Activity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A summary of every visit and token you have ever taken.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _miniStat('TOTAL VISITS', '12')),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(child: _miniStat('AVG WAIT', '18m')),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(child: _miniStat('THIS MONTH', '2')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          toggle,
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─── ACTIVE/HISTORY TOGGLE ──────────────────────────────────────────────────

class _ActiveHistoryToggle extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  final bool invert;
  const _ActiveHistoryToggle({
    required this.current,
    required this.onChanged,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = invert
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFE9E4F5);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final selected = i == current;
          final label = i == 0 ? 'Active' : 'History';
          final pillColor = selected
              ? (invert
                  ? Colors.white
                  : AppColors.primary)
              : Colors.transparent;
          final fg = invert
              ? (selected ? AppColors.primaryDark : Colors.white)
              : (selected ? Colors.white : AppColors.textSecondary);
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: selected && !invert
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── TOKEN HERO CARD ────────────────────────────────────────────────────────

class _TokenHeroCard extends StatelessWidget {
  final String tokenNumber;
  final int minutesAway;
  final String department;
  final String doctor;
  final String wing;
  final String current;
  final String ahead;

  const _TokenHeroCard({
    required this.tokenNumber,
    required this.minutesAway,
    required this.department,
    required this.doctor,
    required this.wing,
    required this.current,
    required this.ahead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cardGreenMedium.withValues(alpha: 0.6),
                width: 6,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'YOUR TURN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#$tokenNumber',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'In $minutesAway mins',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            department,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$doctor • $wing',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _heroStat('CURRENT', '#$current')),
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(child: _heroStat('AHEAD', ahead)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── SECTION LABEL ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      );
}

// ─── DEPARTMENT TEAM ROW ────────────────────────────────────────────────────

class _TeamMember {
  final String name;
  final String role;
  final String room;
  final bool isPrimary;
  const _TeamMember({
    required this.name,
    required this.role,
    required this.room,
    required this.isPrimary,
  });
}

class _DoctorStatusRow extends StatelessWidget {
  final _TeamMember member;
  const _DoctorStatusRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(40),
        border: member.isPrimary
            ? Border.all(color: AppColors.primary, width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardGreenMedium,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              member.isPrimary
                  ? Icons.local_hospital_rounded
                  : Icons.person_rounded,
              color: AppColors.primaryDark,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (member.isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YOUR DOCTOR',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${member.role} • ${member.room}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardGreenMedium,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active Now',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── UP NEXT TILE ───────────────────────────────────────────────────────────

class _UpNext {
  final String token;
  final String queueType;
  final String delta;
  const _UpNext({
    required this.token,
    required this.queueType,
    required this.delta,
  });
}

class _UpNextTile extends StatelessWidget {
  final String token;
  final String queueType;
  final String doctor;
  final String delta;
  const _UpNextTile({
    required this.token,
    required this.queueType,
    required this.doctor,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEAF6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              token,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$queueType • ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: doctor,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            delta,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATE FILTER CHIPS ──────────────────────────────────────────────────────

class _DateFilterChips extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _DateFilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['This Month', 'Last 3 Months', 'All Time'];
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = i == current;
        return Padding(
          padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryDark
                    : const Color(0xFFE9E4F5),
                borderRadius: BorderRadius.circular(28),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── VISIT HISTORY CARD ─────────────────────────────────────────────────────

class _VisitHistoryCard extends StatelessWidget {
  static const _visits = [
    _Visit(
      date: 'April 09, 2024',
      reason: 'General Health Checkup • Dr. Sharma',
      tokenNumber: '047',
      department: 'Cardiology',
      waitTime: '18 min',
    ),
    _Visit(
      date: 'Feb 23, 2024',
      reason: 'Ophthalmology • Dr. Kumar',
      tokenNumber: '022',
      department: 'Ophthalmology',
      waitTime: '12 min',
    ),
    _Visit(
      date: 'Nov 15, 2023',
      reason: 'Annual Screening • Dr. Lee',
      tokenNumber: '014',
      department: 'General Medicine',
      waitTime: '7 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Visit History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_visits.length} visits',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._visits.asMap().entries.map(
                (e) => _VisitTimelineItem(
                  visit: e.value,
                  isLast: e.key == _visits.length - 1,
                ),
              ),
        ],
      ),
    );
  }
}

class _Visit {
  final String date;
  final String reason;
  final String tokenNumber;
  final String department;
  final String waitTime;
  const _Visit({
    required this.date,
    required this.reason,
    required this.tokenNumber,
    required this.department,
    required this.waitTime,
  });
}

class _VisitTimelineItem extends StatelessWidget {
  final _Visit visit;
  final bool isLast;
  const _VisitTimelineItem({required this.visit, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryDark,
                      width: 2.2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.cardGreenBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        visit.date,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Token #${visit.tokenNumber}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    visit.reason,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardGreenMedium,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Waited ${visit.waitTime}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── YOUR PAST TOKENS ───────────────────────────────────────────────────────

class _YourPastTokensCard extends StatelessWidget {
  static const _items = [
    _PastToken(
      token: '047',
      title: 'Cardiology Consultation',
      doctor: 'Dr. Sharma',
      date: 'Apr 09',
      consultationTime: '14m 22s',
    ),
    _PastToken(
      token: '022',
      title: 'Eye Examination',
      doctor: 'Dr. Kumar',
      date: 'Feb 23',
      consultationTime: '9m 08s',
    ),
    _PastToken(
      token: '014',
      title: 'Annual Screening',
      doctor: 'Dr. Lee',
      date: 'Nov 15',
      consultationTime: '11m 35s',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Past Tokens',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tokens you have been served, with the time you spent with the doctor.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ..._items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PastTokenRow(item: t),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastToken {
  final String token;
  final String title;
  final String doctor;
  final String date;
  final String consultationTime;
  const _PastToken({
    required this.token,
    required this.title,
    required this.doctor,
    required this.date,
    required this.consultationTime,
  });
}

class _PastTokenRow extends StatelessWidget {
  final _PastToken item;
  const _PastTokenRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            item.token,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${item.doctor} • ${item.date}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.consultationTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'with doctor',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
