import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import '../../../models/program_model.dart';
import '../add_client_screen.dart';
import '../create_program_screen.dart';
import 'coach_messages_tab.dart';
import 'coach_programs_tab.dart';

class CoachDashboardTab extends StatefulWidget {
  const CoachDashboardTab({super.key});

  @override
  State<CoachDashboardTab> createState() => _CoachDashboardTabState();
}

class _CoachDashboardTabState extends State<CoachDashboardTab> {
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('coach_profile_image_$uid');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _localImageFile = File(imagePath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String coachId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface, 
      body: RefreshIndicator(
        onRefresh: _loadLocalImage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── [1] Gradient Header + Stat Cards ──
              _buildHeaderWithStats(context, coachId),
              const SizedBox(height: 80),
      
              // ── [2] Quick Actions ──
              _buildQuickActions(),
              const SizedBox(height: 32),
      
              // ── [3] Recent Client Activity ──
              _buildRecentClientActivity(),
              const SizedBox(height: 32),
      
              // ── [4] This Week's Schedule ──
              _buildThisWeekSchedule(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. HEADER  — gradient + overlapping stat cards
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeaderWithStats(BuildContext context, String coachId) {
    return StreamBuilder<UserModel?>(
      stream: DatabaseService().userProfileStream(coachId),
      builder: (context, snapshot) {
        final coach = snapshot.data;
        final String displayName = (coach?.fullName ?? 'Coach').split(' ').first;
        final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(coach?.fullName ?? 'Coach')}&background=random&color=fff';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Gradient backdrop with a curved bottom ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              decoration: const BoxDecoration(
                gradient: AppTheme.splashGradient,
                borderRadius: BorderRadius.only(),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$displayName! 👋',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coach Dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          backgroundImage: _localImageFile != null 
                              ? FileImage(_localImageFile!) as ImageProvider
                              : NetworkImage(avatarUrl),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3 Stat Cards floating at bottom ──
            Positioned(
              bottom: -70,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<UserModel>>(
                      stream: DatabaseService().getCoachClientsStream(coachId),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return _statCard(
                          '$count',
                          'Active Clients',
                          Icons.people_outline_rounded,
                          AppTheme.primary,
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<int>(
                      stream: DatabaseService().getUnreadMessagesCountStream(coachId),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _statCard(
                          '$count',
                          'Pending Messages',
                          Icons.chat_bubble_outline_rounded,
                          const Color(0xFF4CAF50),
                          badgeCount: count,
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<List<ProgramModel>>(
                      stream: DatabaseService().getProgramsStream(coachId),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return _statCard(
                          '$count',
                          'Programs Created',
                          Icons.assignment_outlined,
                          const Color(0xFFF5A623),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, {int badgeCount = 0}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4B4B), // Premium red
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: badgeCount > 0 ? const Color(0xFFFF4B4B) : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMedium,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. QUICK ACTIONS — 2×2 grid inside a single white container
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionCardText('+', 'Add Client', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddClientScreen()),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCardText('+', 'Create Program', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateProgramScreen()),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionCardIcon(
                    Icons.chat_bubble_outline_rounded,
                    'Messages',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachMessagesTab(showBackButton: true)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCardIcon(
                    Icons.assignment_outlined,
                    'Programs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachProgramsTab(showBackButton: true)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Quick action card with "+" text symbol
  Widget _actionCardText(String symbol, String label, {VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textDark.withOpacity(0.8),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick action card with icon styled properly
  Widget _actionCardIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppTheme.textDark.withOpacity(0.8)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. RECENT CLIENT ACTIVITY — clean single card with dividers
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRecentClientActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Client Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEDED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _clientRow(
                  'John Smith',
                  'Last active:\n3/30/2026',
                  'https://randomuser.me/api/portraits/men/44.jpg',
                  true,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xFFF2F2F2),
                  indent: 72,
                  endIndent: 16,
                ),
                _clientRow(
                  'Emma Davis',
                  'Last active:\n3/28/2026',
                  'https://randomuser.me/api/portraits/women/44.jpg',
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientRow(String name, String sub, String avatarUrl, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. THIS WEEK'S SCHEDULE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildThisWeekSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Week's Schedule",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _scheduleCard(
            'Monday',
            '10:00 AM',
            'Check-in Call',
            'with Sarah Johnson',
          ),
          const SizedBox(height: 12),
          _scheduleCard(
            'Wednesday',
            '2:00 PM',
            '1-on-1\nSession',
            'with John Smith',
          ),
          const SizedBox(height: 12),
          _scheduleCard(
            'Friday',
            '11:00 AM',
            'Progress\nReview',
            'with Emma Davis',
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(String day, String time, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 24,
              thickness: 1,
              color: Color(0xFFF2F2F2),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textDark,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
