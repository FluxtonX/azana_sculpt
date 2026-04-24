// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:azana_sculpt/screens/home/wedgits.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/streak_service.dart';
import '../../services/badge_service.dart';
import '../../models/streak_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/streak_banner.dart';
import '../../widgets/daily_motivation_card.dart';
import '../../widgets/community_proof_strip.dart';
import '../progress/progress_screen.dart';
import '../meals/meals_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/workout_progress_service.dart';
import '../../models/user_model.dart';
import '../../models/program_model.dart';
import '../../models/workout_models.dart';
import '../../widgets/coach_card.dart';
import '../coaches/all_coaches_screen.dart';
import '../workouts/excercises_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  File? _localImageFile;
  double _fitnessScore = 0.0; // Added for dynamic fitness score

  // Stream Caching to prevent flickering
  Stream<UserModel?>? _userStream;
  Stream<List<ProgramModel>>? _programStream;
  String? _lastCoachId;

  // Cache for workout streams

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
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
    _initStreakAndBadges();
    _loadLocalImage();

    // Initialize user stream once
    final uid = AuthService().currentUser?.uid ?? '';
    _userStream = DatabaseService().userProfileStream(uid);
  }

  Future<void> _loadFitnessScore() async {
    final progress = await WorkoutProgressService().loadProgress();
    if (!mounted) return;
    setState(() {
      _fitnessScore = progress.fitnessScore;
    });
  }

  Future<void> _refreshWorkoutProgress() async {
    await _loadFitnessScore();
    await _initStreakAndBadges();
  }

  void _openHomeTab() {
    setState(() {
      _currentIndex = 0;
    });
    unawaited(_refreshWorkoutProgress());
  }

  void _openProgressTab() {
    setState(() {
      _currentIndex = 3;
    });
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
    final prefs = await SharedPreferences.getInstance();
    final cachedScore = prefs.getDouble('fitness_score') ?? 0.0;

    if (mounted) {
      setState(() {
        _streak = cached;
        _streakLoaded = true;
        _fitnessScore = cachedScore;
      });
    }

    if (uid != null) {
      // Update streak in background
      final updated = await StreakService().updateStreak(uid);
      if (mounted) setState(() => _streak = updated);

      // Check for new badges
      final newBadges = await BadgeService().checkAndUnlockBadges(
        uid,
        updated.currentStreak,
      );
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: [
            _buildHomeTab(),
            ExerciseFetchScreen(
              driveUrl:
                  'https://drive.google.com/drive/folders/1aCGjE-q2mHanGuS0JecipGHZ3aqAljR0?usp=drive_link',
              onProgressUpdated: _refreshWorkoutProgress,
              onNavigateHome: _openHomeTab,
              onNavigateProgress: _openProgressTab,
            ),
            const MealsScreen(),
            const ProgressScreen(),
            const ProfileScreen(),
          ][_currentIndex],
        ),
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
          _programStream = DatabaseService().getAllProgramsStream(
            coachId: coachId,
          );
        }

        return StreamBuilder<ProgramModel?>(
          stream: userSnapshot.data == null
              ? Stream.value(null)
              : DatabaseService().getActiveProgramStream(
                  userSnapshot.data!.uid,
                  coachId,
                ),
          builder: (context, activeProgramSnapshot) {
            final activeProgram = activeProgramSnapshot.data;

            return RefreshIndicator(
              onRefresh: () async {
                await _initStreakAndBadges();
                await _loadLocalImage();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60), // Top spacing
                      _buildHeader(userSnapshot.data),
                      const SizedBox(height: 24),

                      FitnessScoreCard(
                        score: 0,
                        targetScore: _fitnessScore,
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        "Today's Workout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTodayWorkoutCard(activeProgram),

                      const SizedBox(height: 32),
                      const Text(
                        "Progress Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressSummaryGrid(),

                      const SizedBox(height: 32),
                      _buildWeightProgressCard(),

                      const SizedBox(height: 32),
                      _buildThisWeeksWorkouts(),

                      const SizedBox(height: 32),
                      _buildCoachMessageV2(),

                      const SizedBox(height: 32),
                      _buildSmartInsights(),

                      const SizedBox(height: 32),

                      // ── Older Content Moved Below ──
                      if (_streakLoaded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: StreakBanner(
                            streakCount: _streak.currentStreak,
                            isAtRisk: _streak.isAtRisk,
                          ),
                        ),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CommunityProofStrip(),
                      ),
                      const SizedBox(height: 24),

                      _buildCoachesSection(),
                      const SizedBox(height: 24),

                      const DailyMotivationCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
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
    final name = (profile?.fullName != null && profile!.fullName!.isNotEmpty)
        ? profile.fullName
        : user?.displayName;

    final displayName = (name != null && name.isNotEmpty)
        ? name.split(' ').first
        : 'there';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
        ? 'Good afternoon,'
        : 'Good evening,';

    final nameForAvatar = (name != null && name.isNotEmpty) ? name : 'User';
    final avatarUrl =
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameForAvatar)}&background=D4847A&color=fff';

    return FadeTransition(
      opacity: _headerFade,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 26,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 26,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('👋', style: TextStyle(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready to crush your goals?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4847A).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _localImageFile != null
                  ? Image.file(_localImageFile!, fit: BoxFit.cover)
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFD4847A),
                          alignment: Alignment.center,
                          child: Text(
                            nameForAvatar.isNotEmpty
                                ? nameForAvatar[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutCard(ProgramModel? program) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<WorkoutSession?>(
      stream: program != null
          ? DatabaseService().getNextWorkoutStream(userId, program.id)
          : Stream.value(null),
      builder: (context, snapshot) {
        final workout = snapshot.data;

        // If all workouts are done or no program active, show default labels
        final title = workout?.title ?? "Full Body Strength";
        final exerciseCount = workout?.exercises.length ?? 0;
        final duration = workout?.totalDuration ?? "45 min";

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Image with Pll
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD3888E), Color(0xFFC87E84)],
                        ),
                      ),
                      child: Image.asset(
                        'assets/home/todayWorkout.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBECE1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '12 Weak ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC76F4B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title == "Program Complete! 🎉"
                          ? title
                          : 'Full Body Strength', // Placeholder or use dynamic title
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppTheme.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppTheme.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$exerciseCount exercises',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: WorkoutStartButton(
                        onComplete: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.fitness_center_rounded,
                value: '12',
                subtitle: 'Workouts',
                pillText: '↑ 3 this week',
                pillColor: const Color(0xFF2EB87D),
                pillBgColor: const Color(0xFFE6F5E9),
                assetsImage: 'assets/home/firstCard.png',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                value: '-3.0 lbs',
                subtitle: 'Weight Change',
                pillText: '↓ 1.5% this week',
                pillColor: const Color(0xFFD32F2F),
                pillBgColor: const Color(0xFFFFEBEE),
                assetsImage: 'assets/home/progressSummaryWeightchangePic.png',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.local_fire_department_rounded,
                value: '7 days',
                subtitle: 'Current Streak',
                pillText: 'Best: 14 days',
                pillColor: const Color(0xFFF57C00),
                pillBgColor: const Color(0xFFFFF3E0),
                assetsImage:
                    'assets/home/skg-photography-nYNmiwczfIw-unsplash 2.png',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.bolt_rounded,
                value: '84%',
                subtitle: 'Avg Intensity',
                pillText: '↑ 5% this week',
                pillColor: const Color(0xFF2EB87D),
                pillBgColor: const Color(0xFFE6F5E9),
                assetsImage: 'assets/home/ProgressSummary.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String subtitle,
    required String pillText,
    required Color pillColor,
    required Color pillBgColor,
    String? imageUrl,
    String? assetsImage,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Faded Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.85,
                    child: assetsImage != null
                        ? Image.asset(
                            assetsImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppTheme.primary.withOpacity(0.05),
                                ),
                          )
                        : (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppTheme.primary.withOpacity(0.05),
                                ),
                          )
                        : Container(color: AppTheme.primary.withOpacity(0.05)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFFD4847A)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pillText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: pillColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- New Bottom UI Sections ---

  Widget _buildWeightProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9EFEF), // Light pinkish background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textLight.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppTheme.textLight.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        if (value >= 0 && value < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 25),
                      FlSpot(1, 80),
                      FlSpot(2, 140),
                      FlSpot(3, 50),
                      FlSpot(4, 180),
                      FlSpot(5, 100),
                      FlSpot(6, 180),
                    ],
                    isCurved: true,
                    color: const Color(0xFFC88282),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFFC88282),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFC88282).withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisWeeksWorkouts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "This Week's Workouts",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              "View All",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC88282),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildHorizontalWorkoutCard(
                day: 'Day 1',
                title: 'Upper Body Strength',
                duration: '45 min',
                exercises: '8 exercises',
                imageUrl:
                    'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=2070',
              ),
              const SizedBox(width: 16),
              _buildHorizontalWorkoutCard(
                day: 'Day 2',
                title: 'Lower Body Power',
                duration: '40 min',
                exercises: '6 exercises',
                imageUrl:
                    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=2070',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalWorkoutCard({
    required String day,
    required String title,
    required String duration,
    required String exercises,
    required String imageUrl,
  }) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Intermediate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC76F4B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      exercises,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _PressableButton(
                    onPressed: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4847A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Start Workout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachMessageV2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Message from Your Coach",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E5FF5), // Vibrant blue
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Coach Alex',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '2h ago',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Great progress this week! You're showing amazing consistency. Let's focus on increasing intensity in the next phase. Keep crushing it! 💪",
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Smart Insights",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.coffee_rounded,
          title: 'Consider a Rest Day',
          description:
              "You've trained 7 days straight. Recovery is key for muscle growth.",
          actionText: 'Schedule rest >',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.psychology_rounded,
          title: 'Increase Weight Load',
          description:
              'Your upper body strength has improved. Time to challenge yourself!',
          actionText: 'Adjust plan >',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.bolt_rounded,
          title: 'Peak Performance Time',
          description:
              'You perform best at 6 PM. Schedule tough workouts then.',
          actionText: 'Optimize schedule >',
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9EFEF), // Light pinkish
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD4847A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC88282),
                    ),
                  ),
                ),
              ],
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
              ? DatabaseService().getChatUnreadCountStream(
                  '${uid}_${user!.coachId}',
                  uid,
                )
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
                  if (index == 0) {
                    unawaited(_refreshWorkoutProgress());
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.textLight,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/home.png', false),
                    activeIcon: _buildNavIcon('assets/icons/home.png', true),
                    label: 'Home',
                  ),

                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/workout.png', false),
                    activeIcon: _buildNavIcon('assets/icons/workout.png', true),
                    label: 'Workouts',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/meals.png', false),
                    activeIcon: _buildNavIcon('assets/icons/meals.png', true),
                    label: 'Meals',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavIcon('assets/icons/progress.png', false),
                    activeIcon: _buildNavIcon(
                      'assets/icons/progress.png',
                      true,
                    ),
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

  Widget _buildCoachesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Elite Coaches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllCoachesScreen()),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<UserModel>>(
            stream: DatabaseService().getCoachesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final coaches = snapshot.data ?? [];

              if (coaches.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.divider.withOpacity(0.5),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'No coaches available yet.',
                      style: TextStyle(color: AppTheme.textLight),
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coaches.length,
                itemBuilder: (context, index) {
                  return CoachCard(
                    coach: coaches[index],
                    onTap: () {
                      // Navigate to coach profile if needed
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
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
      child: ScaleTransition(scale: _scale, child: widget.child),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutStartButton extends StatefulWidget {
  final VoidCallback onComplete;
  const WorkoutStartButton({super.key, required this.onComplete});

  @override
  State<WorkoutStartButton> createState() => _WorkoutStartButtonState();
}

class _WorkoutStartButtonState extends State<WorkoutStartButton> {
  String _state = 'idle'; // idle, loading, success

  void _start() async {
    setState(() => _state = 'loading');
    
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1800));
    
    if (mounted) {
      setState(() => _state = 'success');
    }
    
    // Show success for a moment
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      widget.onComplete();
      // Reset after a delay so it's ready when user comes back
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _state = 'idle');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return Center(
          child: GestureDetector(
            onTap: _state == 'idle' ? _start : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              width: _state == 'idle' ? maxWidth : 56,
              height: 56,
              decoration: BoxDecoration(
                color: _state == 'success' ? const Color(0xFF2EB87D) : const Color(0xFFD4847A),
                borderRadius: BorderRadius.circular(_state == 'idle' ? 16 : 28),
                boxShadow: [
                  BoxShadow(
                    color: (_state == 'success' ? const Color(0xFF2EB87D) : const Color(0xFFD4847A)).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_state == 'idle') {
      return const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          key: ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start Workout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          ],
        ),
      );
    } else if (_state == 'loading') {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    } else {
      return const Icon(
        key: ValueKey('success'),
        Icons.check_rounded,
        color: Colors.white,
        size: 32,
      );
    }
  }
}
