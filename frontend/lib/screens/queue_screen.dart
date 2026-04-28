import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/queue_status_item.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _selectedNavIndex = 1;

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
                  children: [
                    _buildQueueInfoCard(),
                    _buildFullQueueList(),
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
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Live Queue',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueInfoCard() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Position',
                    style: TextStyle(
                      color: AppColors.mintGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Token 047',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.successGreen,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      '6 in queue',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.mintGreen),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Being Served',
                '042',
                Icons.person,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.mintGreen.withOpacity(0.5),
              ),
              _buildStat(
                'Ahead of You',
                '5',
                Icons.people,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.mintGreen.withOpacity(0.5),
              ),
              _buildStat(
                'Wait Time',
                '~15 min',
                Icons.access_time,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.mintGreen,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mintGreen,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFullQueueList() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Queue Status',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          QueueStatusItem(
            tokenNumber: 42,
            status: 'IN CONSULT',
            patientType: 'NEW PATIENT',
            additionalInfo: 'Dr. Chameli • 20 min',
          ),
          QueueStatusItem(
            tokenNumber: 43,
            status: 'WAITING',
            patientType: 'REPORT SHOWING',
            estimatedTime: '~7 min',
          ),
          QueueStatusItem(
            tokenNumber: 44,
            status: 'WAITING',
            patientType: 'FOLLOW UP',
            estimatedTime: '~6 min',
          ),
          QueueStatusItem(
            tokenNumber: 45,
            status: 'WAITING',
            patientType: 'NEW PATIENT',
            estimatedTime: '~15 min',
          ),
          QueueStatusItem(
            tokenNumber: 46,
            status: 'WAITING',
            patientType: 'REPORT SHOWING',
            estimatedTime: '~8 min',
          ),
          QueueStatusItem(
            tokenNumber: 47,
            status: 'YOU',
            patientType: 'NEW PATIENT',
            additionalInfo: 'Next in line • 15 min',
            isCurrentUser: true,
          ),
          QueueStatusItem(
            tokenNumber: 48,
            status: 'WAITING',
            patientType: 'FOLLOW UP',
            estimatedTime: '~20 min',
          ),
          QueueStatusItem(
            tokenNumber: 49,
            status: 'WAITING',
            patientType: 'NEW PATIENT',
            estimatedTime: '~25 min',
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
        // Already on queue
        break;
      case 3:
        Navigator.pushNamed(context, '/booking');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
}
