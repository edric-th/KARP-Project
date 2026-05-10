import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/app_strings.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'GENERAL'),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                label: 'Language',
                trailing: 'English',
                color: const Color(0xFF10B981),
                onTap: () => _snack(context, 'Language settings'),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                color: const Color(0xFF8B5CF6),
                trailing: 'Off',
                onTap: () => _snack(context, 'Dark mode toggle'),
              ),
              _SettingsTile(
                icon: Icons.text_fields_rounded,
                label: 'Font Size',
                color: AppColors.info,
                trailing: 'Medium',
                onTap: () => _snack(context, 'Font size settings'),
              ),
            ]),
            const SizedBox(height: 24),
            _SectionTitle(title: 'NOTIFICATIONS'),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                color: const Color(0xFFF59E0B),
                trailing: 'On',
                onTap: () => _snack(context, 'Notification settings'),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Email Notifications',
                color: AppColors.primary,
                trailing: 'On',
                onTap: () => _snack(context, 'Email notification settings'),
              ),
              _SettingsTile(
                icon: Icons.vibration_rounded,
                label: 'Queue Alerts',
                color: const Color(0xFFEC4899),
                trailing: 'On',
                onTap: () => _snack(context, 'Queue alert settings'),
              ),
            ]),
            const SizedBox(height: 24),
            _SectionTitle(title: 'PRIVACY & SECURITY'),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                color: const Color(0xFF3B82F6),
                onTap: () => _snack(context, 'Change password'),
              ),
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                label: 'Biometric Lock',
                color: AppColors.primary,
                trailing: 'Off',
                onTap: () => _snack(context, 'Biometric settings'),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: AppStrings.privacyPolicy,
                color: AppColors.textMuted,
                onTap: () => _snack(context, 'Privacy policy'),
              ),
            ]),
            const SizedBox(height: 24),
            _SectionTitle(title: 'ABOUT'),
            const SizedBox(height: 10),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: AppStrings.aboutApp,
                color: AppColors.textMuted,
                onTap: () => _showAbout(context),
              ),
              _SettingsTile(
                icon: Icons.star_outline_rounded,
                label: 'Rate App',
                color: const Color(0xFFF59E0B),
                onTap: () => _snack(context, 'Rate app on store'),
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: AppStrings.helpSupport,
                color: AppColors.info,
                onTap: () => _snack(context, 'Help & Support'),
              ),
            ]),
            const SizedBox(height: 28),
            Center(
              child: Text(
                'Mero Palo v1.0.0',
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
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

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About Mero Palo',
            style: TextStyle(fontFamily: 'Inter', 
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'Mero Palo is a hospital queue management system designed to reduce wait times and improve patient experience in Nepal.\n\nVersion 1.0.0\n© 2026 KARP Team',
          style: TextStyle(fontFamily: 'Inter', 
              fontSize: 14, color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(fontFamily: 'Inter', 
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTile> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: children.asMap().entries.map((e) {
            final isLast = e.key == children.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast) const Divider(height: 1, indent: 62),
              ],
            );
          }).toList(),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      );
}
