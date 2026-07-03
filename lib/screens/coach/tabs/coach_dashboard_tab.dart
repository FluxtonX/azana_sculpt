import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../create_program_screen.dart';
import '../coach_assign_meals_screen.dart';
import 'coach_messages_tab.dart';
import '../../../constants/app_theme.dart';
import '../../../services/database_service.dart';
import '../../../models/user_model.dart';

class CoachDashboardTab extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  final ValueChanged<int>? onTabChange;

  const CoachDashboardTab({super.key, this.onMenuPressed, this.onTabChange});

  @override
  State<CoachDashboardTab> createState() => _CoachDashboardTabState();
}

class _CoachDashboardTabState extends State<CoachDashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  final Color primaryColor = AppTheme.primary;

  final Color _bgColor = const Color(0xFFF5F2EF);
  final Color _darkColor = const Color(0xFF171412);
  final Color _mutedColor = const Color(0xFF837873);
  final Color _softPrimary = const Color(0xFFFFF0EB);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final String coachId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 58, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<UserModel>>(
                stream: DatabaseService().getCoachClientsStream(coachId),
                builder: (context, clientSnapshot) {
                  final clients = clientSnapshot.data ?? [];

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService().getCoachAssignmentsHistoryStream(
                      coachId,
                    ),
                    builder: (context, assignmentSnapshot) {
                      final assignments = assignmentSnapshot.data ?? [];
                      final todayStr = DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.now());

                      final todaysAssignments = assignments.where((a) {
                        final assignedDate = (a['assignedAt'] as String)
                            .split('T')
                            .first;
                        return assignedDate == todayStr;
                      }).toList();

                      final completedCount = todaysAssignments
                          .where((a) => a['status'] == 'completed')
                          .length;

                      final totalCount = todaysAssignments.length;

                      final completionRate = totalCount > 0
                          ? completedCount / totalCount
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroHeader(
                            date: today,
                            activeClients: clients.length,
                            todayTasks: totalCount,
                          ),
                          const SizedBox(height: 26),
                          _buildSectionHeader(
                            title: "Today's Assignments",
                            actionText: "Manage",
                            onTap: () => widget.onTabChange?.call(2),
                          ),
                          const SizedBox(height: 14),
                          _buildAssignmentsCard(
                            totalCount,
                            completedCount,
                            completionRate,
                          ),
                          const SizedBox(height: 28),
                          _buildClientEngagement(clients),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 18),
              _buildQuickActions(),
              const SizedBox(height: 18),
              _buildDailyReminders(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required String date,
    required int activeClients,
    required int todayTasks,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF251716),
            primaryColor.withOpacity(0.85),
            const Color(0xFFD17763),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.24),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassPill(date),
                  GestureDetector(
                    onTap: widget.onMenuPressed,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Good afternoon,\nCoach 👋",
                style: GoogleFonts.outfit(
                  fontSize: 33,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your clients are waiting for today's guidance.",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.76),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStat(
                      value: activeClients.toString(),
                      label: "Active Clients",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeroStat(
                      value: todayTasks.toString(),
                      label: "Today Tasks",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeroStat({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _darkColor,
            letterSpacing: -0.4,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentsCard(int total, int completed, double rate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(radius: 28),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Workout Videos",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _darkColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "$total assigned • $completed completed",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.10).animate(
                  CurvedAnimation(
                    parent: _pulseController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: _iconBox(Icons.videocam_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildProgressRing(rate),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(value: total, label: "Assigned"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniStat(
                        value: completed,
                        label: "Completed",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _buildPrimaryButton(
            text: "MANAGE ASSIGNMENTS",
            icon: Icons.arrow_forward_rounded,
            onTap: () => widget.onTabChange?.call(2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double rate) {
    final percentage = (rate * 100).toInt();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: rate.clamp(0.0, 1.0)),
      builder: (context, value, _) {
        return SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFF1E8E3),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "$percentage%",
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _darkColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat({required int value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 900),
            tween: IntTween(begin: 0, end: value),
            builder: (context, animatedValue, _) {
              return Text(
                animatedValue.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: _darkColor,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientEngagement(List<UserModel> clients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "Client Engagement",
          actionText: "View All",
          onTap: () {},
        ),
        const SizedBox(height: 14),
        if (clients.isEmpty)
          _buildEmptyState(
            "No clients yet",
            "Add clients to see their activity.",
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: clients.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildClientCard(clients[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildClientCard(UserModel client) {
    final String name = client.fullName ?? client.email.split('@').first;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "C";

    return Container(
      width: 148,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'client_avatar_${client.uid}',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  backgroundImage: client.profileImageUrl != null
                      ? NetworkImage(client.profileImageUrl!)
                      : null,
                  child: client.profileImageUrl == null
                      ? Text(
                          initial,
                          style: GoogleFonts.outfit(
                            color: primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -1,
                  bottom: 2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E9B63),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                "${client.streakCount ?? 0} day streak",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              "● ACTIVE",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E9B63),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: "Quick Actions"),
        const SizedBox(height: 10),
        GridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 1.25,
          children: [
            _buildActionCard(
              "Assign\nVideo",
              Icons.movie_creation_rounded,
              onTap: () => widget.onTabChange?.call(2),
            ),
            _buildActionCard(
              "Add\nProgram",
              Icons.add_box_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateProgramScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              "Message\nClient",
              Icons.chat_bubble_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CoachMessagesTab(showBackButton: true),
                  ),
                );
              },
            ),
            _buildActionCard(
              "Meal\nPDF",
              Icons.picture_as_pdf_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CoachAssignMealsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: _cardDecoration(radius: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBox(icon, size: 42, iconSize: 22),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: "Daily Reminders"),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(radius: 28),
          child: Column(
            children: [
              _buildReminderItem(
                icon: Icons.notifications_active_rounded,
                title: "Review today's check-ins",
                sub: "3 clients haven't completed their workout yet",
              ),
              Divider(color: Colors.black.withOpacity(0.06), height: 28),
              _buildReminderItem(
                icon: Icons.assignment_rounded,
                title: "Prepare weekly program review",
                sub: "Scheduled for tomorrow morning",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderItem({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(icon, size: 36, iconSize: 18),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.78)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.26),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, {double size = 48, double iconSize = 24}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _softPrimary,
        borderRadius: BorderRadius.circular(size * 0.38),
      ),
      child: Icon(icon, color: primaryColor, size: iconSize),
    );
  }

  Widget _buildEmptyState(String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        children: [
          _iconBox(Icons.people_outline_rounded),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF37261F).withOpacity(0.07),
          blurRadius: 35,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}
