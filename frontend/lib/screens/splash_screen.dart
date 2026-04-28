import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'MeroPalo Care',
      'subtitle': 'मेरो पालो',
      'tagline': 'YOUR TURN, YOUR TIME',
      'by': 'KARP',
    },
    {
      'title': 'Skip the Queue',
      'subtitle': 'Book appointments & track your turn in real-time',
      'tagline': '',
      'by': '',
    },
    {
      'title': 'Smart Healthcare',
      'subtitle': 'AI-powered assistance for better healthcare experience',
      'tagline': '',
      'by': '',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A4A3A),
              AppColors.primaryGreen,
              Color(0xFF1B8A6B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    return _buildPage(
                      data['title']!,
                      data['subtitle']!,
                      data['tagline']!,
                      data['by']!,
                    );
                  },
                ),
              ),
              _buildProgressIndicator(),
              const SizedBox(height: AppSpacing.xl),
              _buildNextButton(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(String title, String subtitle, String tagline, String by) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.mintGreen,
                width: 8,
              ),
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  size: 60,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.mintGreen,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (tagline.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              tagline,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (by.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            RichText(
              text: const TextSpan(
                text: 'By ',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: 'KARP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _onboardingData.length,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textWhite),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _onboardingData.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? AppColors.textWhite
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _navigateToNext,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward,
          color: AppColors.textWhite,
          size: 28,
        ),
      ),
    );
  }
}
