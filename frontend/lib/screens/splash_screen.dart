import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Simulate checking authentication state
    await Future.delayed(const Duration(seconds: 2));

    // For now, navigate to login screen
    // In a real app, check SharedPreferences or secure storage here
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(
                Icons.local_hospital_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // App Name
            Text(
              'Mero Palo',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // App Slogan
            Text(
              'Smart Queue Management System',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Loading Indicator
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Initializing...',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
