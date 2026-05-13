import 'package:flutter/material.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/main_nav_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/hospitals_screen.dart';
import 'package:frontend/screens/hospital_detail_screen.dart';
import 'package:frontend/screens/doctors_screen.dart';
import 'package:frontend/screens/doctor_detail_screen.dart';
import 'package:frontend/screens/book_appointment_screen.dart';
import 'package:frontend/screens/booking_success_screen.dart';
import 'package:frontend/screens/payment_screen.dart';
import 'package:frontend/screens/queue_screen.dart';
import 'package:frontend/screens/queue_detail_screen.dart';
import 'package:frontend/screens/queue_token_screen.dart';
import 'package:frontend/screens/appointments_screen.dart';
import 'package:frontend/screens/notifications_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/medical_history_screen.dart';
import 'package:frontend/screens/about_us_screen.dart';
import 'package:frontend/screens/support_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String hospitals = '/hospitals';
  static const String hospitalDetail = '/hospital-detail';
  static const String doctors = '/doctors';
  static const String doctorDetail = '/doctor-detail';
  static const String bookAppointment = '/book-appointment';
  static const String payment = '/payment';
  static const String bookingSuccess = '/booking-success';
  static const String queue = '/queue';
  static const String queueDetail = '/queue-detail';
  static const String queueToken = '/queue-token';
  static const String appointments = '/appointments';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String medicalHistory = '/medical-history';
  static const String aboutUs = '/about-us';
  static const String support = '/support';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), routeSettings);

      case login:
        return _buildRoute(const LoginScreen(), routeSettings);

      case signup:
      case register:
        return _buildRoute(const SignupScreen(), routeSettings);

      case main:
        return _buildRoute(const MainNavScreen(), routeSettings);

      case home:
        return _buildRoute(const HomeScreen(), routeSettings);

      case hospitals:
        return _buildRoute(const HospitalsScreen(), routeSettings);

      case hospitalDetail:
        final hospital = routeSettings.arguments as HospitalModel;
        return _buildRoute(
          HospitalDetailScreen(hospital: hospital),
          routeSettings,
        );

      case doctors:
        return _buildRoute(const DoctorsScreen(), routeSettings);

      case doctorDetail:
        final doctor = routeSettings.arguments as DoctorModel;
        return _buildRoute(
          DoctorDetailScreen(doctor: doctor),
          routeSettings,
        );

      case bookAppointment:
        final doctor = routeSettings.arguments as DoctorModel?;
        return _buildRoute(
          BookAppointmentScreen(preselectedDoctor: doctor),
          routeSettings,
        );

      case payment:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return _buildRoute(
          PaymentScreen(
            doctor: args['doctor'] as DoctorModel,
            hospital: args['hospital'] as HospitalModel?,
            appointmentType: args['appointmentType'] as AppointmentType,
            speciality: args['speciality'] as String,
            problem: args['problem'] as String? ?? '',
            notes: args['notes'] as String? ?? '',
            patientName: args['patientName'] as String,
            patientPhone: args['patientPhone'] as String? ?? '',
            patientAge: args['patientAge'] as int,
            patientGender: args['patientGender'] as String? ?? 'Male',
            tokenNumber: args['tokenNumber'] as int,
            notifyMe: (args['notifyMe'] as bool?) ?? true,
          ),
          routeSettings,
        );

      case bookingSuccess:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          BookingSuccessScreen(
            doctor: args?['doctor'] as DoctorModel?,
            date: args?['date'] as String?,
            time: args?['time'] as String?,
            appointmentType: args?['appointmentType'] as AppointmentType?,
            speciality: args?['speciality'] as String?,
            tokenNumber: args?['tokenNumber'] as int?,
            notifyMe: (args?['notifyMe'] as bool?) ?? true,
            patientName: args?['patientName'] as String?,
          ),
          routeSettings,
        );

      case queue:
        return _buildRoute(const QueueScreen(), routeSettings);

      case queueDetail:
        final queueModel = routeSettings.arguments as QueueModel;
        return _buildRoute(
          QueueDetailScreen(queue: queueModel),
          routeSettings,
        );

      case queueToken:
        final queueModel = routeSettings.arguments as QueueModel;
        return _buildRoute(
          QueueTokenScreen(queue: queueModel),
          routeSettings,
        );

      case appointments:
        return _buildRoute(const AppointmentsScreen(), routeSettings);

      case notifications:
        return _buildRoute(const NotificationsScreen(), routeSettings);

      case profile:
        return _buildRoute(const ProfileScreen(), routeSettings);

      case editProfile:
        return _buildRoute(const EditProfileScreen(), routeSettings);

      case settings:
        return _buildRoute(const SettingsScreen(), routeSettings);

      case medicalHistory:
        return _buildRoute(const MedicalHistoryScreen(), routeSettings);

      case aboutUs:
        return _buildRoute(const AboutUsScreen(), routeSettings);

      case support:
        return _buildRoute(const SupportScreen(), routeSettings);

      default:
        return _buildRoute(const LoginScreen(), routeSettings);
    }
  }

  static MaterialPageRoute _buildRoute(
    Widget page,
    RouteSettings routeSettings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: routeSettings,
    );
  }
}
