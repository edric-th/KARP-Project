import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SideDrawer extends StatelessWidget {
  final String userName;
  final String token;
  final String specialization;
  final Function(String) onNavigate;

  const SideDrawer({
    super.key,
    required this.userName,
    required this.token,
    required this.specialization,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.backgroundWhite,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  isSelected: true,
                  onTap: () => onNavigate('home'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.hourglass_empty_outlined,
                  title: 'Live Queue',
                  onTap: () => onNavigate('queue'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () => onNavigate('profile'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.description_outlined,
                  title: 'Medical History',
                  onTap: () => onNavigate('history'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () => onNavigate('about'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => onNavigate('settings'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _DrawerItem(
                  icon: Icons.help_outline,
                  title: 'Support',
                  onTap: () => onNavigate('support'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: TextButton.icon(
                onPressed: () => onNavigate('logout'),
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.errorRed,
                ),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(AppBorderRadius.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MeroPalo Care',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'मेरो पालो',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(userName),
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildChip('Token $token'),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          specialization,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 10,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.substring(0, 2).toUpperCase();
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.lightMint : Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryGreen : AppColors.textMedium,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
