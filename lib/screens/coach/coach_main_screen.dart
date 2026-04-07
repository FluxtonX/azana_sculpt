import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import 'tabs/coach_dashboard_tab.dart';
import 'tabs/coach_clients_tab.dart';
import 'tabs/coach_programs_tab.dart';
import 'tabs/coach_messages_tab.dart';
import 'tabs/coach_profile_tab.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key});

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CoachDashboardTab(),
    CoachClientsTab(),
    CoachProgramsTab(),
    CoachMessagesTab(),
    CoachProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final String coachId = AuthService().currentUser?.uid ?? '';

    return StreamBuilder<int>(
      stream: DatabaseService().getUnreadMessagesCountStream(coachId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore Error (Check for missing index link): ${snapshot.error}');
        }
        
        final unreadCount = snapshot.data ?? 0;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.surfaceCard,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textLight,
              selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Clients',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  activeIcon: Icon(Icons.collections_bookmark),
                  label: 'Programs',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text('$unreadCount'),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: const Color(0xFFFF4B4B),
                    child: const Icon(Icons.chat_bubble_outline),
                  ),
                  activeIcon: Badge(
                    label: Text('$unreadCount'),
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: const Color(0xFFFF4B4B),
                    child: const Icon(Icons.chat_bubble),
                  ),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
