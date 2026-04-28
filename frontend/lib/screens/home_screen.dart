import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/side_drawer.dart';
import '../widgets/token_card.dart';
import '../widgets/queue_status_item.dart';
import '../widgets/ai_chat_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundWhite,
      drawer: SideDrawer(
        userName: 'Aryan Thakuri',
        token: '047',
        specialization: 'General chamelian',
        onNavigate: (route) {
          Navigator.pop(context);
          _handleNavigation(route);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    TokenCard(
                      servingToken: 42,
                      doctorName: 'Dr. Chameli',
                      specialization: 'General Consultation',
                      userToken: 47,
                      waitingTime: '~15 min',
                    ),
                    _buildQueueStatusHeader(),
                    _buildQueueList(),
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
      floatingActionButton: AIChatButton(
        onPressed: () {
          _showAIChatDialog();
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const Icon(
              Icons.menu,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const Text(
            'MeroPalo Care',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textWhite,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData emoji;

    if (hour < 12) {
      greeting = 'Good morning';
      emoji = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      emoji = Icons.wb_sunny;
    } else {
      greeting = 'Good evening';
      emoji = Icons.nightlight_outlined;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$greeting, ',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              Icon(
                emoji,
                color: Colors.amber,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textMedium,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Chameli Hospital',
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                '•',
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Token 047',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Live Queue Status',
            style: AppTextStyles.headlineMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            ),
            child: const Text(
              '6 people in queue',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          QueueStatusItem(
            tokenNumber: 42,
            status: 'IN CONSULT',
            patientType: 'NEW PATIENT',
            additionalInfo: '20 min',
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
        ],
      ),
    );
  }

  void _handleNavigation(String route) {
    switch (route) {
      case 'home':
        setState(() {
          _selectedNavIndex = 0;
        });
        break;
      case 'queue':
        setState(() {
          _selectedNavIndex = 1;
        });
        break;
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        setState(() {
          _selectedNavIndex = 4;
        });
        break;
      case 'logout':
        _showLogoutDialog();
        break;
      default:
    }
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Home - already on home
        break;
      case 1:
        // Queue
        Navigator.pushNamed(context, '/queue');
        break;
      case 2:
        // FAB - AI/Smart feature
        _showAIChatDialog();
        break;
      case 3:
        // Booking
        Navigator.pushNamed(context, '/booking');
        break;
      case 4:
        // Settings
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _showAIChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.primaryGreen,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('AI Assistant'),
          ],
        ),
        content: const Text(
          'How can I help you today? Ask me anything about your appointment, queue status, or medical records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/splash');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
