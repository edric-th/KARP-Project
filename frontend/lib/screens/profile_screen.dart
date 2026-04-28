import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/info_row.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedNavIndex = 4;

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
                    _buildProfileHeader(),
                    _buildVisitSummary(),
                    _buildPersonalInfo(),
                    _buildMedicalInfo(),
                    _buildAccountInfo(),
                    _buildDeleteAccount(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const Text(
            'Profile',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'AT',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.textWhite,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Aryan Thakuri',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Token 047 • City Chameli Hospital',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: const Text(
              'ACTIVE PATIENT',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitSummary() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VISIT SUMMARY',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '12',
                  label: 'TOTAL VISITS',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  value: '18m',
                  label: 'AVG WAIT',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  value: '11',
                  label: 'COMPLETED',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL INFORMATION',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.person_outline,
                  label: 'FULL NAME',
                  value: 'Aryan Thakuri',
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'PHONE NUMBER',
                  value: '+977 9845437057',
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'AGE & DOB',
                  value: '21 Years • 14 Oct 2006',
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.transgender_outlined,
                  label: 'GENDER',
                  value: 'Male',
                  valueColor: AppColors.primaryGreen,
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.bloodtype_outlined,
                  label: 'BLOOD GROUP',
                  value: 'B+',
                  valueColor: AppColors.bloodBPositiveText,
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'IDENTITY NUMBER',
                  value: '•••• •••• 5678',
                  trailing: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEDICAL INFORMATION',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              children: [
                _buildMedicalInfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'KNOWN ALLERGIES',
                  chips: [
                    {'label': 'short memory loss', 'color': AppColors.chipOrange},
                    {'label': 'Dust', 'color': AppColors.chipOrange},
                  ],
                  onAdd: () {},
                ),
                const Divider(),
                _buildMedicalInfoRow(
                  icon: Icons.favorite_outlined,
                  label: 'CHRONIC CONDITIONS',
                  chips: [
                    {'label': 'Hypertension', 'color': AppColors.chipRed},
                  ],
                  onAdd: () {},
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.medication_outlined,
                  label: 'CURRENT MEDICATIONS',
                  value: 'Amlodipine 5mg (Daily)',
                  trailing: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.emergency_outlined,
                  label: 'EMERGENCY CONTACT',
                  value: '(Mother)\n+977 9867574843',
                  trailing: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      '+ Add',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildMedicalInfoRow({
    required IconData icon,
    required String label,
    required List<Map<String, dynamic>> chips,
    VoidCallback? onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textMedium,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall,
                    ),
                    if (onAdd != null)
                      GestureDetector(
                        onTap: onAdd,
                        child: const Text(
                          '+ Add',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: chips.map((chip) => _buildChip(
                    chip['label'] as String,
                    chip['color'] as Color,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.email_outlined,
                  label: 'EMAIL ADDRESS',
                  value: 'aryanchameli69@gmail.com',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: const Text(
                          'Unverified',
                          style: TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Text(
                        'Verify',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.lock_outline,
                  label: 'PASSWORD',
                  value: '••••••••••••',
                  trailing: const Text(
                    'Change',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDeleteAccount() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                _showDeleteAccountDialog();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'This will permanently remove all your data from MeroPalo servers.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/splash');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
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
