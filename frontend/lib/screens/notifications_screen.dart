import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

enum _NotifKind { queueTurn, queueUpdate, booking, alert, tokenReg, doctor, missed, feedback }

class _Notif {
  final String title;
  final String body;
  final DateTime time;
  final _NotifKind kind;
  final bool isUrgent;
  final bool isRead;
  const _Notif({
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.isUrgent = false,
    this.isRead = false,
  });

  _Notif copyWith({bool? isRead}) => _Notif(
        title: title,
        body: body,
        time: time,
        kind: kind,
        isUrgent: isUrgent,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_Notif> _items;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    final yesterday = today.subtract(const Duration(days: 1));
    _items = [
      _Notif(
        title: 'Your turn is almost here!',
        body:
            'Patient ID: MP-8829-22 is currently next in line at Department of Cardiology.',
        time: now,
        kind: _NotifKind.queueTurn,
        isUrgent: true,
      ),
      _Notif(
        title: 'Queue Update',
        body: 'Estimated wait time for OPD has decreased by 12 minutes.',
        time: now.subtract(const Duration(minutes: 10)),
        kind: _NotifKind.queueUpdate,
      ),
      _Notif(
        title: 'Booking Confirmed',
        body:
            'Your appointment with Dr. Mehta for tomorrow at 10:30 AM is confirmed.',
        time: now.subtract(const Duration(minutes: 30)),
        kind: _NotifKind.booking,
      ),
      _Notif(
        title: 'Alert Activated',
        body: 'Safety protocols updated for the main ward. Review guidelines.',
        time: now.subtract(const Duration(hours: 1)),
        kind: _NotifKind.alert,
      ),
      _Notif(
        title: 'Token Registered',
        body: 'Your walk-in token #442 has been successfully registered.',
        time: today.subtract(const Duration(hours: 3)),
        kind: _NotifKind.tokenReg,
      ),
      _Notif(
        title: 'Dr. Priya Sharma is now available',
        body: 'The consultant has started her session.',
        time: today.subtract(const Duration(hours: 4)),
        kind: _NotifKind.doctor,
      ),
      _Notif(
        title: 'Token Missed',
        body: 'Your turn for Token #201 was called at 5:30 PM.',
        time: yesterday.add(const Duration(hours: 7, minutes: 30)),
        kind: _NotifKind.missed,
      ),
      _Notif(
        title: 'How was your experience?',
        body: 'We\'d love to hear your feedback on your visit yesterday.',
        time: yesterday,
        kind: _NotifKind.feedback,
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final groups = _groupByBucket(_items);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _GreenHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                for (final entry in groups.entries) ...[
                  _SectionLabel(entry.key),
                  const SizedBox(height: 12),
                  _NotifGroupCard(
                    items: entry.value,
                    onTap: (idx) {
                      final orig = _items.indexOf(entry.value[idx]);
                      if (orig != -1) {
                        setState(() {
                          _items[orig] =
                              _items[orig].copyWith(isRead: true);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<_Notif>> _groupByBucket(List<_Notif> items) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    final today = <_Notif>[];
    final earlierToday = <_Notif>[];
    final yesterday = <_Notif>[];
    final earlier = <_Notif>[];

    for (final n in items) {
      if (n.time.isAfter(startOfToday)) {
        if (now.difference(n.time).inHours < 2) {
          today.add(n);
        } else {
          earlierToday.add(n);
        }
      } else if (n.time.isAfter(startOfYesterday)) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    final out = <String, List<_Notif>>{};
    if (today.isNotEmpty) out['TODAY'] = today;
    if (earlierToday.isNotEmpty) out['EARLIER TODAY'] = earlierToday;
    if (yesterday.isNotEmpty) out['YESTERDAY'] = yesterday;
    if (earlier.isNotEmpty) out['EARLIER'] = earlier;
    return out;
  }
}

// ─── GREEN HEADER ─────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 18),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECTION LABEL (with trailing rule) ───────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ],
    );
  }
}

// ─── NOTIF GROUP CARD ─────────────────────────────────────────────────────

class _NotifGroupCard extends StatelessWidget {
  final List<_Notif> items;
  final void Function(int) onTap;
  const _NotifGroupCard({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _NotifRow(
              notif: items[i],
              onTap: () => onTap(i),
            ),
            if (i != items.length - 1)
              Divider(
                height: 1,
                indent: 70,
                endIndent: 16,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

// ─── NOTIF ROW ────────────────────────────────────────────────────────────

class _NotifRow extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  const _NotifRow({required this.notif, required this.onTap});

  IconData _iconFor(_NotifKind k) {
    switch (k) {
      case _NotifKind.queueTurn:
        return Icons.alarm_rounded;
      case _NotifKind.queueUpdate:
        return Icons.groups_rounded;
      case _NotifKind.booking:
        return Icons.check_circle_outline_rounded;
      case _NotifKind.alert:
        return Icons.notifications_active_outlined;
      case _NotifKind.tokenReg:
        return Icons.confirmation_number_outlined;
      case _NotifKind.doctor:
        return Icons.local_hospital_rounded;
      case _NotifKind.missed:
        return Icons.warning_amber_rounded;
      case _NotifKind.feedback:
        return Icons.rate_review_outlined;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? "s" : ""} ago';
    if (diff.inDays == 1) {
      final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final m = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday, $h:$m $period';
    }
    return 'Yesterday';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingAvatar(kind: notif.kind, icon: _iconFor(notif.kind)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (notif.isUrgent)
                        Text(
                          'URGENT',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif.time),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingAvatar extends StatelessWidget {
  final _NotifKind kind;
  final IconData icon;
  const _LeadingAvatar({required this.kind, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (kind == _NotifKind.doctor) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardGreenMedium,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardGreenBorder, width: 1.4),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.primaryDark,
          size: 22,
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardGreenLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}
