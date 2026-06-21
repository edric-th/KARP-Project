import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // The bottom nav hides while the user scrolls down and reappears when they
  // scroll back up; an idle scroll leaves it as-is.
  bool _navVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args != _currentIndex) {
      _currentIndex = args.clamp(0, 3);
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _selectTab(int index) => setState(() {
        _currentIndex = index;
        _navVisible = true; // always reveal the bar when switching tabs
      });

  /// React to scrolls bubbling up from whichever child screen is active.
  bool _onScroll(UserScrollNotification n) {
    // Ignore non-vertical / zero-extent scrollables (e.g. horizontal chips).
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse && _navVisible) {
      setState(() => _navVisible = false); // scrolling down → hide
    } else if (n.direction == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true); // scrolling up → show
    }
    return false; // let the notification keep bubbling
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onMenuTap: _openDrawer),
      QueueScreen(onMenuTap: _openDrawer),
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
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        offset: _navVisible ? Offset.zero : const Offset(0, 1.3),
        child: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _selectTab,
          onCenterTap: () => Navigator.pushNamed(context, '/queue-ai-chat'),
        ),
      ),
    );
  }
}
