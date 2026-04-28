import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/booking_success_screen.dart';
import 'screens/queue_screen.dart';

void main() {
  runApp(const MeroPaloApp());
}

class MeroPaloApp extends StatelessWidget {
  const MeroPaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeroPalo Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/booking': (context) => const BookingScreen(),
        '/booking-success': (context) => const BookingSuccessScreen(),
        '/queue': (context) => const QueueScreen(),
      },
    );
  }
}
