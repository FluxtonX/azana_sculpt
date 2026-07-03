import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';
import '../screens/coach/analytics_screen.dart';
import '../screens/coach/schedule_screen.dart';
import '../screens/coach/transformations_screen.dart';
import '../screens/coach/content_library_screen.dart';
import '../screens/coach/tabs/coach_programs_tab.dart';
import '../screens/coach/create_program_screen.dart';

class CoachDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const CoachDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.7,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "A'ZANA SCULPT",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    "Explore All Screens",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSectionTitle('MAIN'),
                  _buildDrawerItem(0, Icons.home_outlined, 'Dashboard', context),
                  _buildDrawerItem(2, Icons.video_camera_back_outlined, 'Assignments', context),
                  _buildDrawerItem(1, Icons.people_outline, 'Clients', context),
                  _buildDrawerItem(3, Icons.chat_bubble_outline, 'Messages', context),
                  _buildDrawerItem(4, Icons.person_outline, 'Profile', context),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('FEATURES'),
                  _buildDrawerItem(-1, Icons.fitness_center, 'Programs', context, destination: const CoachProgramsTab(showBackButton: true)),
                  _buildDrawerItem(-1, Icons.add, 'Program Builder', context, destination: const CreateProgramScreen()),
                  _buildDrawerItem(-1, Icons.camera_alt_outlined, 'Transformations', context, destination: const TransformationsScreen()),
                  _buildDrawerItem(-1, Icons.bar_chart_outlined, 'Analytics', context, destination: const AnalyticsScreen()),
                  _buildDrawerItem(-1, Icons.calendar_today_outlined, 'Schedule', context, destination: const ScheduleScreen()),
                  _buildDrawerItem(-1, Icons.folder_open_outlined, 'Content Library', context, destination: const ContentLibraryScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label, BuildContext context, {Widget? destination}) {
    final bool isSelected = index == currentIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () async {
          Navigator.pop(context);
          if (destination != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
            if (result is int) {
              onTabChange(result);
            }
          } else if (index != -1) {
            onTabChange(index);
          }
        },
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AppTheme.textDark,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textDark,
          ),
        ),
        visualDensity: const VisualDensity(vertical: -2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
