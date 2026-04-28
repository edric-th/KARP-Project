import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/visit_history_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedNavIndex = 4;
  bool _expandedFaq1 = false;
  bool _expandedFaq2 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSupportSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDataSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _handleNavTap(index);
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textWhite,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACCOUNT',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildListItem(
            icon: Icons.person_outline,
            title: 'Profile',
            trailing: Icons.chevron_right,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildListItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Icons.chevron_right,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUPPORT',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightPurpleBg,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Help & FAQ',
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFaqItem(
                  question: 'How to reschedule a visit?',
                  isExpanded: _expandedFaq1,
                  onToggle: () {
                    setState(() {
                      _expandedFaq1 = !_expandedFaq1;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildFaqItem(
                  question: 'Where can I see my lab results?',
                  isExpanded: _expandedFaq2,
                  onToggle: () {
                    setState(() {
                      _expandedFaq2 = !_expandedFaq2;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.lightPurpleBg,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Need Immediate Assistance?',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Our support team is available 24/7 for patient care inquiries.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
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

  Widget _buildDataSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DATA',
                style: AppTextStyles.labelSmall,
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightPurpleBg,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Past Visits',
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                VisitHistoryCard(
                  date: 'OCT 12, 2023',
                  hospital: 'Chameli Hospital Central',
                  doctor: 'Dr. Kull Chameli',
                  specialization: 'Cardiology',
                  waitTime: '14 min',
                  isLast: false,
                ),
                const SizedBox(height: AppSpacing.md),
                VisitHistoryCard(
                  date: 'SEP 28, 2023',
                  hospital: 'MeroPalo Chameli Clinic',
                  doctor: 'Dr. Chameli Prawn',
                  specialization: 'Pediatrics',
                  waitTime: '8 min',
                  isLast: true,
                  isCompleted: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Icon(
                trailing,
                color: AppColors.textLight,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/queue');
        break;
      case 2:
        // FAB action
        break;
      case 3:
        Navigator.pushNamed(context, '/booking');
        break;
      case 4:
        // Already on settings
        break;
    }
  }
}
