import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/queue/screens/queue_screen.dart';
import '../../features/booking/screens/booking_type_screen.dart';
import '../../features/booking/screens/booking_specialist_screen.dart';
import '../../features/booking/screens/booking_appointment_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_success_screen.dart';

/// App router configuration using go_router.
/// All routes for the Mero Palo application are defined here.
class AppRouter {
  AppRouter._(); // Private constructor to prevent instantiation

  // Route names (path identifiers)
  static const String home = '/';
  static const String queue = '/queue';
  static const String bookingTypeSelection = '/booking/type';
  static const String bookingSpecialistSelection = '/booking/specialist';
  static const String bookingConfirmation = '/booking/confirm';
  static const String bookingSuccess = '/booking/success';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      // Home screen route
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) {
          return const HomeScreen();
        },
      ),

      // Queue status screen route
      GoRoute(
        path: queue,
        name: 'queue',
        builder: (context, state) {
          return const QueueScreen();
        },
      ),

      // Booking flow - Type selection route
      GoRoute(
        path: bookingTypeSelection,
        name: 'bookingType',
        builder: (context, state) {
          return const BookingTypeScreen();
        },
      ),

      // Booking flow - Specialist selection route
      GoRoute(
        path: bookingSpecialistSelection,
        name: 'bookingSpecialist',
        builder: (context, state) {
          return const BookingSpecialistScreen();
        },
      ),

      // Booking flow - Confirmation route
      GoRoute(
        path: bookingConfirmation,
        name: 'bookingConfirm',
        builder: (context, state) {
          return const BookingConfirmationScreen();
        },
      ),

      // Booking flow - Appointment time selection route
      GoRoute(
        path: '/booking/appointment',
        name: 'bookingAppointment',
        builder: (context, state) {
          return const BookingAppointmentScreen();
        },
      ),

      // Booking success screen route
      GoRoute(
        path: bookingSuccess,
        name: 'bookingSuccess',
        builder: (context, state) {
          return const BookingSuccessScreen();
        },
      ),

      // Profile screen route
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) {
          // TODO: Import and use ProfileScreen
          return const SizedBox(); // Placeholder
        },
      ),

      // Settings screen route
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) {
          // TODO: Import and use SettingsScreen
          return const SizedBox(); // Placeholder
        },
      ),
    ],

    // Error page handler
    errorBuilder: (context, state) {
      // TODO: Create a custom error screen
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Page not found: ${state.uri}'),
        ),
      );
    },
  );
}
