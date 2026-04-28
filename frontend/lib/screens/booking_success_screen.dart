import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessIcon(),
              const SizedBox(height: AppSpacing.lg),
              _buildSuccessMessage(),
              const SizedBox(height: AppSpacing.xl),
              _buildTokenCard(),
              const SizedBox(height: AppSpacing.md),
              _buildNotificationInfo(),
              const Spacer(),
              _buildButtons(context),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.mintGreen,
          width: 8,
        ),
      ),
      child: const Icon(
        Icons.check,
        color: AppColors.textWhite,
        size: 48,
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return const Column(
      children: [
        Text(
          'Booking Successful!',
          style: AppTextStyles.headlineLarge,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Your appointment has been secured.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTokenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightPurpleBg,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: const Text(
              'TOKEN NUMBER',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Aryan Thakuri',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Your token number:',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '047',
            style: AppTextStyles.tokenMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Dr. Chameli',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'GENERAL MEDICINE',
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 18,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                'Estimated wait: ',
                style: AppTextStyles.bodyMedium,
              ),
              const Text(
                '~1 hours',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: const Text(
              'You will receive a push notification 2 tokens before your turn. Please arrive at the clinic on time.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
            ),
            child: const Text('Go to Home'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/queue');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
            ),
            child: const Text('View Queue'),
          ),
        ),
      ],
    );
  }
}
