import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/coach_drawer.dart';
import 'tabs/coach_assignments_tab.dart';
import 'tabs/coach_clients_tab.dart';
import 'tabs/coach_dashboard_tab.dart';
import 'tabs/coach_messages_tab.dart';
import 'tabs/coach_profile_tab.dart';

class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key});

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final String coachId = AuthService().currentUser?.uid ?? '';

    final List<Widget> tabs = [
      SafeTab(
        tabName: 'Dashboard',
        child: CoachDashboardTab(
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          onTabChange: (index) => setState(() => _currentIndex = index),
        ),
      ),
      SafeTab(
        tabName: 'Clients',
        child: CoachClientsTab(
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ),
      SafeTab(
        tabName: 'Assignments',
        child: CoachAssignmentsTab(
          onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ),
      SafeTab(tabName: 'Messages', child: const CoachMessagesTab()),
      SafeTab(tabName: 'Profile', child: const CoachProfileTab()),
    ];

    return StreamBuilder<int>(
      stream: DatabaseService().getUnreadMessagesCountStream(coachId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Firestore Error (Check for missing index link): ${snapshot.error}',
          );
        }

        final unreadCount = snapshot.data ?? 0;

        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          backgroundColor: const Color(0xFFF7F2EF),
          endDrawer: CoachDrawer(
            currentIndex: _currentIndex,
            onTabChange: (index) {
              setState(() => _currentIndex = index);
            },
          ),
          body: IndexedStack(index: _currentIndex, children: tabs),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 35,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    badgeCount: 0,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    badgeCount: 0,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.video_camera_back_outlined,
                    activeIcon: Icons.video_camera_back_rounded,
                    badgeCount: 0,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    badgeCount: unreadCount,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    badgeCount: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required int badgeCount,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isSelected ? 52 : 44,
        height: isSelected ? 52 : 44,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withOpacity(0.78),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 20 : 16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppTheme.textLight,
              size: isSelected ? 25 : 23,
            ),
            if (badgeCount > 0)
              Positioned(
                top: 4,
                right: 3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SafeTab extends StatefulWidget {
  final Widget child;
  final String tabName;

  const SafeTab({super.key, required this.child, required this.tabName});

  @override
  State<SafeTab> createState() => _SafeTabState();
}

class _SafeTabState extends State<SafeTab> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading ${widget.tabName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final originalErrorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      ErrorWidget.builder = originalErrorBuilder;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
          });
        }
      });

      debugPrint('==================================================');
      debugPrint('FLUTTER ERROR IN TAB: ${widget.tabName}');
      debugPrint('Exception: ${details.exception}');
      debugPrint('Stack Trace:\n${details.stack}');
      debugPrint('==================================================');

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    };

    try {
      final built = widget.child;
      ErrorWidget.builder = originalErrorBuilder;
      return built;
    } catch (e, stack) {
      ErrorWidget.builder = originalErrorBuilder;
      debugPrint('==================================================');
      debugPrint('FLUTTER SYNCHRONOUS ERROR IN TAB: ${widget.tabName}');
      debugPrint('Exception: $e');
      debugPrint('Stack Trace:\n$stack');
      debugPrint('==================================================');
      return Scaffold(body: Center(child: Text('Error: $e')));
    }
  }
}
