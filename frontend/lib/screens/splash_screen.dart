import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_router.dart';
import '../widgets/common/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Devanagari glyphs aren't in Inter, so fall back to platform Nepali fonts.
  static const List<String> _devanagariFallback = [
    'Noto Sans Devanagari',
    'Kohinoor Devanagari',
    'Mangal',
  ];

  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // The loading bar fills over the splash duration, then we move on.
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNext();
      }
    });
  }

  void _goToNext() {
    // In a real app, check stored auth here and route accordingly.
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 1.1,
            colors: [
              Color(0xFF15825F),
              Color(0xFF0C5A42),
              Color(0xFF063D2E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Official brand logo on a clean white card.
              const AppLogo(size: 160, borderRadius: 32),

              const SizedBox(height: 40),

              // Brand: "Mero पालो Care"
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontFamilyFallback: _devanagariFallback,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  children: const [
                    TextSpan(text: 'Mero'),
                    TextSpan(text: 'पालो'),
                    TextSpan(text: ' Care'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Devanagari subtitle
              const Text(
                'मेरो पालो',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontFamilyFallback: _devanagariFallback,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              // Tagline
              Text(
                'YOUR TURN, YOUR TIME',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),

              const SizedBox(height: 18),

              // Attribution
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  children: const [
                    TextSpan(text: 'By '),
                    TextSpan(
                      text: 'KARP',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 4),

              // Loading bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _loadingController.value,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final bool isActive = index == 1;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 9 : 7,
                    height: isActive ? 9 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: isActive ? 0.9 : 0.35,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
