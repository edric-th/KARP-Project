import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreenHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 10),
                  _AccountCard(
                    items: [
                      _AccountTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile'),
                      ),
                      _AccountTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () =>
                            Navigator.pushNamed(context, '/notifications'),
                      ),
                      _AccountTile(
                        icon: Icons.auto_awesome,
                        label: 'Queue AI Assistant',
                        onTap: () =>
                            Navigator.pushNamed(context, '/queue-ai-chat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _SectionLabel('SUPPORT'),
                  const SizedBox(height: 10),
                  _HelpFaqCard(),
                  const SizedBox(height: 14),
                  _AssistanceCard(
                    onCall: () => _snack(context, 'Calling support…'),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _SectionLabel('DATA'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _snack(context, 'Viewing all visits'),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PastVisitsCard(),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Mero Palo v1.0.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
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

  void _snack(BuildContext context, String msg) {
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

// ─── GREEN HEADER ──────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
            'Settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
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

// ─── SECTION LABEL ─────────────────────────────────────────────────────────

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
          letterSpacing: 1.1,
        ),
      );
}

// ─── ACCOUNT CARD ──────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final List<_AccountTile> items;
  const _AccountCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELP & FAQ CARD ───────────────────────────────────────────────────────

class _HelpFaqCard extends StatefulWidget {
  @override
  State<_HelpFaqCard> createState() => _HelpFaqCardState();
}

class _HelpFaqCardState extends State<_HelpFaqCard> {
  final List<_Faq> _items = [
    _Faq(
      question: 'How to reschedule a visit?',
      answer:
          'Open the Appointments tab, choose the upcoming visit you want to change, and tap Reschedule to pick a new slot.',
    ),
    _Faq(
      question: 'Where can I see my lab results?',
      answer:
          'Lab results appear under your Medical Records inside the Profile page once your hospital has uploaded them.',
    ),
  ];
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Help & FAQ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.asMap().entries.map((e) {
            final isOpen = _open.contains(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() {
                  if (isOpen) {
                    _open.remove(e.key);
                  } else {
                    _open.add(e.key);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.value.question,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            e.value.answer,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  _Faq({required this.question, required this.answer});
}

// ─── ASSISTANCE CARD ───────────────────────────────────────────────────────

class _AssistanceCard extends StatelessWidget {
  final VoidCallback onCall;
  const _AssistanceCard({required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardGreenMedium,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Need Immediate Assistance?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our support team is available 24/7 for patient care inquiries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCall,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Call Now',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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

// ─── PAST VISITS CARD ──────────────────────────────────────────────────────

class _PastVisitsCard extends StatelessWidget {
  static const _visits = [
    _Visit(
      date: 'OCT 12, 2023',
      hospital: 'Chameli Hospital Central',
      doctor: 'Dr. Kull Chameli',
      specialty: 'Cardiology',
      waitTime: '14 min',
      completed: true,
    ),
    _Visit(
      date: 'SEP 28, 2023',
      hospital: 'MeroPalo Chameli Clinic',
      doctor: 'Dr. Chameli Prawn',
      specialty: 'Pediatrics',
      waitTime: '8 min',
      completed: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Past Visits',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._visits.asMap().entries.map((e) {
            final isLast = e.key == _visits.length - 1;
            return _TimelineVisitTile(
              visit: e.value,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _Visit {
  final String date;
  final String hospital;
  final String doctor;
  final String specialty;
  final String waitTime;
  final bool completed;
  const _Visit({
    required this.date,
    required this.hospital,
    required this.doctor,
    required this.specialty,
    required this.waitTime,
    required this.completed,
  });
}

class _TimelineVisitTile extends StatelessWidget {
  final _Visit visit;
  final bool isLast;
  const _TimelineVisitTile({required this.visit, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: visit.completed
                        ? AppColors.primary
                        : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visit.completed
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: visit.completed
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.cardGreenBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.date,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        if (visit.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardGreenMedium,
                              borderRadius: BorderRadius.circular(12),
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      visit.hospital,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visit.doctor} • ${visit.specialty}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Wait time: ${visit.waitTime}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
