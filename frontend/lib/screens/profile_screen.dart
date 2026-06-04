import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showIdentity = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  String _emergencyText(Map<String, dynamic> c) {
    final name = (c['name'] ?? '').toString();
    final relation = (c['relation'] ?? '').toString();
    final phone = (c['phone'] ?? '').toString();
    if (name.isEmpty && phone.isEmpty) return 'Not provided';
    final head = relation.isNotEmpty ? '$name ($relation)' : name;
    return [head, phone].where((s) => s.isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final initials = profile.initials;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _GreenHeader(
              title: 'Profile',
              showLeading: false,
              trailing: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _AvatarBlock(
              initials: initials,
              onEdit: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email.isEmpty ? 'MeroPalo patient' : profile.email,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Text(
                'ACTIVE PATIENT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('VISIT SUMMARY'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _VisitStatCard(
                          value: '${profile.stats.totalVisits}',
                          label: 'TOTAL VISITS'),
                      const SizedBox(width: 10),
                      _VisitStatCard(
                          value: '${profile.stats.avgWaitMinutes}m',
                          label: 'AVG WAIT'),
                      const SizedBox(width: 10),
                      _VisitStatCard(
                          value: '${profile.stats.completed}',
                          label: 'COMPLETED'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('PERSONAL INFORMATION'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'FULL NAME',
                        value: profile.displayName,
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'PHONE NUMBER',
                        value: profile.phone.isEmpty ? '—' : profile.phone,
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'AGE & DOB',
                        value: profile.age != null
                            ? '${profile.age} Years${profile.dateOfBirth.isNotEmpty ? ' · ${profile.dateOfBirth}' : ''}'
                            : (profile.dateOfBirth.isNotEmpty
                                ? profile.dateOfBirth
                                : '—'),
                      ),
                      const _RowDivider(),
                      _InfoRowChip(
                        icon: Icons.transgender_rounded,
                        label: 'GENDER',
                        chipText: profile.gender.isEmpty ? '—' : profile.gender,
                        chipColor: const Color(0xFFDFE7FB),
                        chipTextColor: const Color(0xFF1F4E8C),
                      ),
                      const _RowDivider(),
                      _InfoRowChip(
                        icon: Icons.water_drop_outlined,
                        label: 'BLOOD GROUP',
                        chipText:
                            profile.bloodGroup.isEmpty ? '—' : profile.bloodGroup,
                        chipColor: const Color(0xFFFDE0E0),
                        chipTextColor: const Color(0xFFB42323),
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'IDENTITY NUMBER',
                        value: _showIdentity
                            ? '1234 5678 5678'
                            : '•••• •••• 5678',
                        trailing: GestureDetector(
                          onTap: () => setState(
                              () => _showIdentity = !_showIdentity),
                          child: Icon(
                            _showIdentity
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('MEDICAL INFORMATION'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      _MedicalRow(
                        icon: Icons.medical_information_outlined,
                        label: 'KNOWN ALLERGIES',
                        onAdd: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                        children: profile.allergies.isEmpty
                            ? null
                            : profile.allergies
                                .map((a) => _MedicalChip(
                                      text: a,
                                      color: const Color(0xFFFDE0C4),
                                      textColor: const Color(0xFF8A4B14),
                                    ))
                                .toList(),
                        valueText:
                            profile.allergies.isEmpty ? 'None recorded' : null,
                      ),
                      const _RowDivider(),
                      _MedicalRow(
                        icon: Icons.monitor_heart_outlined,
                        label: 'CHRONIC CONDITIONS',
                        onAdd: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                        children: profile.chronicConditions.isEmpty
                            ? null
                            : profile.chronicConditions
                                .map((c) => _MedicalChip(
                                      text: c,
                                      color: const Color(0xFFFDE0E0),
                                      textColor: const Color(0xFFB42323),
                                    ))
                                .toList(),
                        valueText: profile.chronicConditions.isEmpty
                            ? 'None recorded'
                            : null,
                      ),
                      const _RowDivider(),
                      _MedicalRow(
                        icon: Icons.medication_outlined,
                        label: 'CURRENT MEDICATIONS',
                        onAdd: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                        valueText: profile.currentMedications.isEmpty
                            ? 'None recorded'
                            : profile.currentMedications
                                .map((m) => [m['name'], m['dose']]
                                    .where((e) => e != null && '$e'.isNotEmpty)
                                    .join(' '))
                                .where((s) => s.isNotEmpty)
                                .join('\n'),
                      ),
                      const _RowDivider(),
                      _MedicalRow(
                        icon: Icons.contact_emergency_outlined,
                        label: 'EMERGENCY CONTACT',
                        onAdd: () =>
                            Navigator.pushNamed(context, '/edit-profile'),
                        valueText: _emergencyText(profile.primaryContact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('ACCOUNT'),
                  const SizedBox(height: 10),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'EMAIL ADDRESS',
                        value: profile.email,
                        valueExtra: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE0E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Unverified',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB42323),
                            ),
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () => _addStub('Verify email'),
                          child: Text(
                            'Verify',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const _RowDivider(),
                      _InfoRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'PASSWORD',
                        value: '•••••••••••••',
                        trailing: GestureDetector(
                          onTap: () => _addStub('Change password'),
                          child: Text(
                            'Change',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'This will permanently remove all your data from MeroPalo servers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addStub(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
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
              'Delete Account?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This action is permanent. All your appointments, queues and medical info will be deleted.',
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
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
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
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (_) => false);
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
                      'Delete',
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

// ─── GREEN HEADER ──────────────────────────────────────────────────────────

class _GreenHeader extends StatelessWidget {
  final String title;
  final bool showLeading;
  final Widget? trailing;
  const _GreenHeader({
    required this.title,
    this.showLeading = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final trailingWidget = trailing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (showLeading)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            )
          else
            const SizedBox(width: 22),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (trailingWidget != null) trailingWidget else const SizedBox(width: 22),
        ],
      ),
    );
  }
}

// ─── AVATAR BLOCK ──────────────────────────────────────────────────────────

class _AvatarBlock extends StatelessWidget {
  final String initials;
  final VoidCallback onEdit;
  const _AvatarBlock({required this.initials, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.cardGreenMedium,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardGreenBorder, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2.5),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED UI BITS ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
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

class _VisitStatCard extends StatelessWidget {
  final String value;
  final String label;
  const _VisitStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueExtra;
  final Widget? trailing;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueExtra,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ?valueExtra,
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _InfoRowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String chipText;
  final Color chipColor;
  final Color chipTextColor;
  const _InfoRowChip({
    required this.icon,
    required this.label,
    required this.chipText,
    required this.chipColor,
    required this.chipTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: chipTextColor,
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
}

class _MedicalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onAdd;
  final List<Widget>? children;
  final String? valueText;

  const _MedicalRow({
    required this.icon,
    required this.label,
    required this.onAdd,
    this.children,
    this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final localValue = valueText;
    final localChildren = children;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAdd,
                      child: Text(
                        '+ Add',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (localValue != null)
                  Text(
                    localValue,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                if (localChildren != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: localChildren,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _MedicalChip({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
