import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/queue_screen.dart';
import 'package:frontend/screens/appointments_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/widgets/common/app_drawer.dart';
import 'package:frontend/widgets/common/bottom_nav_bar.dart';

class MainNavScreen extends StatefulWidget {
  final int initialTab;
  const MainNavScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex = widget.initialTab.clamp(0, 3);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args != _currentIndex) {
      _currentIndex = args.clamp(0, 3);
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _selectTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onMenuTap: _openDrawer),
      const QueueScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppDrawer(
        activeIndex: _currentIndex,
        onTabSelected: _selectTab,
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        onCenterTap: () => Navigator.pushNamed(context, '/book-appointment'),
      ),
    );
  }
}
