import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/app_router.dart';
import 'package:frontend/firebase_options.dart';

import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/token_store.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/services/hospital_service.dart';
import 'package:frontend/services/doctor_service.dart';
import 'package:frontend/services/booking_service.dart';
import 'package:frontend/services/queue_service.dart';
import 'package:frontend/services/notification_service.dart';

import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/queue_provider.dart';
import 'package:frontend/providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not fully configured yet (e.g. Android appId / OAuth client).
    // Email/password auth still works via the backend; Google sign-in is
    // unavailable until setup is complete.
    debugPrint('Firebase init skipped: $e');
  }
  runApp(const MeroPaloApp());
}

class MeroPaloApp extends StatefulWidget {
  const MeroPaloApp({super.key});

  @override
  State<MeroPaloApp> createState() => _MeroPaloAppState();
}

class _MeroPaloAppState extends State<MeroPaloApp> {
  // Shared, single-instance data layer.
  late final TokenStore _tokens = TokenStore();
  late final ApiClient _api = ApiClient(_tokens);

  late final AuthService _authService = AuthService(_api, _tokens);
  late final ChatService _chatService = ChatService(_api);
  late final ProfileService _profileService = ProfileService(_api);
  late final HospitalService _hospitalService = HospitalService(_api);
  late final DoctorService _doctorService = DoctorService(_api);
  late final BookingService _bookingService = BookingService(_api);
  late final QueueService _queueService = QueueService(_api);
  late final NotificationService _notificationService =
      NotificationService(_api);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Raw services for one-shot calls from screens.
        Provider<AuthService>.value(value: _authService),
        Provider<ChatService>.value(value: _chatService),
        Provider<HospitalService>.value(value: _hospitalService),
        Provider<DoctorService>.value(value: _doctorService),
        Provider<BookingService>.value(value: _bookingService),
        Provider<QueueService>.value(value: _queueService),
        Provider<ProfileService>.value(value: _profileService),
        Provider<NotificationService>.value(value: _notificationService),
        // Stateful providers.
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(_authService, _profileService)..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(_hospitalService, _doctorService),
        ),
        ChangeNotifierProvider(create: (_) => BookingsProvider(_bookingService)),
        ChangeNotifierProvider(create: (_) => QueueProvider(_queueService)),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(_notificationService),
        ),
      ],
      child: MaterialApp(
        title: 'Mero Palo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.backgroundLight,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: AppColors.backgroundLight,
            foregroundColor: AppColors.textPrimary,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            thickness: 1,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.primary,
          ),
        ),
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
