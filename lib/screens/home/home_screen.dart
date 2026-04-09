// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/streak_service.dart';
import '../../services/badge_service.dart';
import '../../models/streak_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/streak_banner.dart';
import '../../widgets/daily_motivation_card.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/community_proof_strip.dart';
import '../workouts/workouts_screen.dart';
import '../workouts/workout_execution_screen.dart';
import '../programs/program_details_screen.dart';
import '../progress/progress_screen.dart';
import '../meals/meals_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/program_model.dart';
import '../../models/workout_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  File? _localImageFile;

  // Stream Caching to prevent flickering
  Stream<UserModel?>? _userStream;
  Stream<List<ProgramModel>>? _programStream;
  String? _lastCoachId;
  
  // Cache for workout streams
  final Map<String, Stream<WorkoutSession?>> _workoutStreamCache = {};

  void _markMessagesAsRead() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    
    // Get user profile to find coachId
    final user = await DatabaseService().getUserProfile(uid);
    if (user != null && user.coachId != null) {
      final chatId = '${user.uid}_${user.coachId}';
      await DatabaseService().markMessagesAsRead(chatId, user.uid);
    }
  }

  StreakModel _streak = const StreakModel();
  bool _streakLoaded = false;

  late AnimationController _headerController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerController.forward();
    _initStreakAndBadges();
    _loadLocalImage();
    
    // Initialize user stream once
    final uid = AuthService().currentUser?.uid ?? '';
    _userStream = DatabaseService().userProfileStream(uid);
  }

  Future<void> _loadLocalImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('client_profile_image_$uid');
    if (imagePath != null && File(imagePath).existsSync()) {
      if (mounted) {
        setState(() {
          _localImageFile = File(imagePath);
        });
      }
    }
  }

  Future<void> _initStreakAndBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Load from cache first (instant)
    final cached = await StreakService().loadStreak();
    if (mounted) setState(() { _streak = cached; _streakLoaded = true; });

    if (uid != null) {
      // Update streak in background
      final updated = await StreakService().updateStreak(uid);
      if (mounted) setState(() => _streak = updated);

      // Check for new badges
      final newBadges = await BadgeService().checkAndUnlockBadges(uid, updated.currentStreak);
      if (newBadges.isNotEmpty && mounted) {
        _showBadgeUnlockDialog(newBadges.first);
      }
    }
  }

  void _showBadgeUnlockDialog(BadgeModel badge) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _BadgeUnlockDialog(badge: badge),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const WorkoutsScreen(),
          const MealsScreen(),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        final coachId = userSnapshot.data?.coachId;
        
        // Stabilize program stream
        if (_programStream == null || coachId != _lastCoachId) {
          _lastCoachId = coachId;
          _programStream = DatabaseService().getAllProgramsStream(coachId: coachId);
        }

        return StreamBuilder<ProgramModel?>(
          stream: userSnapshot.data == null 
              ? Stream.value(null) 
              : DatabaseService().getActiveProgramStream(userSnapshot.data!.uid, coachId),
          builder: (context, activeProgramSnapshot) {
            final activeProgram = activeProgramSnapshot.data;

            return RefreshIndicator(
              onRefresh: () async {
                await _initStreakAndBadges();
                await _loadLocalImage();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Header + Glassmorphism Workout Card ──
                    SizedBox(
                      height: 440,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          _buildHeader(userSnapshot.data),
                          Positioned(
                            top: 175,
                            left: 20,
                            right: 20,
                            child: _buildTodayWorkoutCard(activeProgram),
                          ),
                        ],
                      ),
                    ),
      
                    // ── Content Below Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
      
                          // Streak Banner
                          if (_streakLoaded)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: StreakBanner(
                                streakCount: _streak.currentStreak,
                                isAtRisk: _streak.isAtRisk,
                              ),
                            )
                          else
                            const SizedBox(height: 20),
      
                          _buildStatsRow(),
                          const SizedBox(height: 16),
      
                          // Community proof strip
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CommunityProofStrip(),
                          ),
                          const SizedBox(height: 24),
      
                          _buildWeeklyProgressCard(),
                          const SizedBox(height: 24),
                          _buildCoachMessageCard(),
                          const SizedBox(height: 24),
      
                          // Dynamic motivation card
                          const DailyMotivationCard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(UserModel? profile) {
    final user = FirebaseAuth.instance.currentUser;
    // Check profile fullName first, then Firebase Auth displayName
    final name = (profile?.fullName != null && profile!.fullName!.isNotEmpty) 
        ? profile.fullName 
        : user?.displayName;
        
    final displayName = (name != null && name.isNotEmpty) 
        ? name.split(' ').first 
        : 'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    
    final nameForAvatar = (name != null && name.isNotEmpty) 
        ? name 
        : 'User';
    final avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameForAvatar)}&background=random&color=fff';

    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        width: double.infinity,
        height: 215,
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        decoration: const BoxDecoration(
          gradient: AppTheme.splashGradient,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$displayName! ',
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text('👋', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your sculpt journey continues today.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _localImageFile != null
                      ? Image.file(_localImageFile!, fit: BoxFit.cover)
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primary.withOpacity(0.1),
                              alignment: Alignment.center,
                              child: Text(
                                nameForAvatar.isNotEmpty ? nameForAvatar[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWorkoutCard(ProgramModel? program) {
    if (program == null) {
      return _buildEmptyWorkoutCard();
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Use getNextWorkoutStream to always suggest the first uncompleted workout
    return StreamBuilder<WorkoutSession?>(
      stream: DatabaseService().getNextWorkoutStream(userId, program.id),
      builder: (context, snapshot) {
        final workout = snapshot.data;
        
        // If all workouts are done, check if we should show a completion message or the last workout
        final title = workout?.title ?? "Program Complete! 🎉";
        final exerciseCount = workout?.exercises.length ?? 0;
        final subtitle = workout != null 
            ? '$exerciseCount Exercises • ${workout.totalDuration}'
            : "You have finished all sessions in this program.";
        final duration = workout?.totalDuration ?? "--";

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppTheme.textDark.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TODAY'S WORKOUT",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textLight,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              duration,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 18),
                  // Dynamic progress bar linked to database
                  StreamBuilder<double>(
                    stream: DatabaseService().getProgramProgressStream(
                        FirebaseAuth.instance.currentUser!.uid, program.id),
                    builder: (context, progressSnapshot) {
                      final progress = progressSnapshot.data ?? 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedProgressBar(value: progress, height: 6),
                          const SizedBox(height: 6),
                          Text(
                            "${(progress * 100).toInt()}% of program complete",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _PressableButton(
                      onPressed: () {
                        if (workout != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutExecutionScreen(session: workout),
                            ),
                          );
                        } else {
                          // Navigate to program details if no direct workout session found
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProgramDetailsScreen(program: program),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 22, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Start Workout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWorkoutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_rounded, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text(
            'No Active Program',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with a coach to get your custom program started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.show_chart_rounded,
            '-2.5kg',
            'This month',
            const Color(0xFFEEF4FF),
            const Color(0xFF5B8DEF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            Icons.calendar_today_rounded,
            '58',
            'Workouts done',
            const Color(0xFFEEFAF6),
            const Color(0xFF2EB87D),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label,
      Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "This Week's Progress",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFAF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '4 / 5 done',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2EB87D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AnimatedProgressBar(value: 0.8, height: 10, duration: Duration(milliseconds: 1200)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayCircle('M', true),
              _buildDayCircle('T', true),
              _buildDayCircle('W', true),
              _buildDayCircle('T', true),
              _buildDayCircle('F', false),
              _buildDayCircle('S', false),
              _buildDayCircle('S', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(String day, bool isDone) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isDone ? AppTheme.primaryGradient : null,
        color: isDone ? null : AppTheme.surface,
        shape: BoxShape.circle,
        border: isDone ? null : Border.all(color: AppTheme.divider),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDone ? Colors.white : AppTheme.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildCoachMessageCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Message from your coach',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                   '1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\"Great progress this week! Keep up the consistency. Remember, small daily improvements lead to big results. 💪\"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          _PressableButton(
            onPressed: () => setState(() => _currentIndex = 3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Reply to Coach',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final uid = AuthService().currentUser?.uid ?? '';
    
    return StreamBuilder<UserModel?>(
      stream: DatabaseService().userProfileStream(uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        
        return StreamBuilder<int>(
          stream: (user?.role == 'coach')
              ? DatabaseService().getUnreadMessagesCountStream(uid)
              : (user?.coachId != null)
                  ? DatabaseService().getChatUnreadCountStream('${uid}_${user!.coachId}', uid)
                  : Stream.value(0),
          builder: (context, countSnapshot) {
            final unreadCount = countSnapshot.data ?? 0;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    _loadLocalImage();
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.textLight,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/home.png', false),
                    activeIcon: _buildNavIcon('assets/icons/home.png', true),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/workout&program.png', false),
                    activeIcon: _buildNavIcon('assets/icons/workout&program.png', true),
                    label: 'Workouts',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/meals.png', false),
                    activeIcon: _buildNavIcon('assets/icons/meals.png', true),
                    label: 'Meals',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/progress.png', false),
                    activeIcon: _buildNavIcon('assets/icons/progress.png', true),
                    label: 'Progress',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      label: Text('$unreadCount'),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: const Color(0xFFFF4B4B),
                      child: _buildNavIcon('assets/icons/profile.png', false),
                    ),
                    activeIcon: Badge(
                      label: Text('$unreadCount'),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: const Color(0xFFFF4B4B),
                      child: _buildNavIcon('assets/icons/profile.png', true),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavIcon(String assetPath, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        color: isActive ? AppTheme.primary : AppTheme.textLight,
      ),
    );
  }
}

/// Pressable button with scale micro-interaction
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _PressableButton({required this.child, required this.onPressed});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class _BadgeUnlockDialog extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeUnlockDialog({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              'New Badge Unlocked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Awesome!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
