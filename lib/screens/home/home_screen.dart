// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:azana_sculpt/screens/home/wedgits.dart';
import 'package:azana_sculpt/services/google_drive_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/streak_service.dart';
import '../../services/badge_service.dart';
import '../../models/streak_model.dart';
import '../../models/badge_model.dart';
import '../../widgets/daily_motivation_card.dart';
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
import '../coaches/coach_detail_screen.dart';
import '../workouts/excercises_screen.dart';
import '../workouts/exercise_detail_screen.dart';
import '../workouts/workout_testing_screen.dart';

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
  Stream<ProgramModel?>? _activeProgramStream;
  Stream<WorkoutProgressSnapshot>? _progressStream;
  Stream<List<Map<String, dynamic>>>? _assignmentsStream;
  Stream<int>? _unreadCountStream;
  String? _lastCoachId;
  String? _lastUserRole;
  StreamSubscription<UserModel?>? _userSubscription;

  // Cache for workout streams

  StreakModel _streak = const StreakModel();
  // bool _streakLoaded = false;

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
    unawaited(_loadFitnessScore());

    // Initialize streams
    final uid = AuthService().currentUser?.uid ?? '';
    _userStream = DatabaseService().userProfileStream(uid).asBroadcastStream();
    _progressStream = Stream.fromFuture(
      WorkoutProgressService().loadProgress(),
    ).asBroadcastStream();
    _assignmentsStream = DatabaseService()
        .getClientAssignmentsStream(uid)
        .asBroadcastStream();

    // Listen to user changes to update dependent streams
    _userSubscription = _userStream?.listen((user) {
      if (user == null) return;

      final uid = user.uid;
      final roleChanged = user.role != _lastUserRole;
      final coachChanged = user.coachId != _lastCoachId;
      final latestScore = user.fitnessScore ?? 0.0;

      if (latestScore != _fitnessScore) {
        setState(() => _fitnessScore = latestScore);
      }

      if (roleChanged || coachChanged) {
        _lastUserRole = user.role;
        _lastCoachId = user.coachId;

        setState(() {
          // Active program stream
          _activeProgramStream = DatabaseService()
              .getActiveProgramStream(uid, user.coachId)
              .asBroadcastStream();

          // Unread messages stream
          if (user.role == 'coach') {
            _unreadCountStream = DatabaseService()
                .getUnreadMessagesCountStream(uid)
                .asBroadcastStream();
          } else if (user.coachId != null) {
            _unreadCountStream = DatabaseService()
                .getChatUnreadCountStream('${uid}_${user.coachId}', uid)
                .asBroadcastStream();
          } else {
            _unreadCountStream = Stream.value(0).asBroadcastStream();
          }
        });
      }
    });
  }

  Future<void> _loadFitnessScore() async {
    final progress = await WorkoutProgressService().loadProgress();
    if (!mounted) return;
    setState(() {
      _fitnessScore = progress.fitnessScore;
      _progressStream = Stream.value(progress).asBroadcastStream();
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

    if (mounted) {
      setState(() {
        _streak = cached;
        // _streakLoaded = true;
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
    _userSubscription?.cancel();
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
        final user = userSnapshot.data;

        return StreamBuilder<ProgramModel?>(
          stream: _activeProgramStream,
          builder: (context, activeProgramSnapshot) {
            final activeProgram = activeProgramSnapshot.data;

            return RefreshIndicator(
              onRefresh: () async {
                await _initStreakAndBadges();
                await _loadFitnessScore();
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
                      _buildHeader(user),
                      const SizedBox(height: 24),

                      FitnessScoreCard(targetScore: _fitnessScore),

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
                      StreamBuilder<WorkoutProgressSnapshot>(
                        stream: _progressStream,
                        builder: (context, progressSnapshot) {
                          return _buildProgressSummaryGrid(
                            user,
                            progressSnapshot.data,
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                      StreamBuilder<WorkoutProgressSnapshot>(
                        stream: _progressStream,
                        builder: (context, progressSnapshot) {
                          return _buildWeightProgressCard(
                            user,
                            progressSnapshot.data,
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _assignmentsStream,
                        builder: (context, assignmentsSnapshot) {
                          return _buildThisWeeksWorkouts(
                            assignmentsSnapshot.data ?? [],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Older Content Moved Below ──
                      // if (_streakLoaded)
                      //   Padding(
                      //     padding: const EdgeInsets.only(bottom: 20),
                      //     child: StreakBanner(
                      //       streakCount: _streak.currentStreak,
                      //       isAtRisk: _streak.isAtRisk,
                      //     ),
                      //   ),

                      // const Align(
                      //   alignment: Alignment.centerLeft,
                      //   child: CommunityProofStrip(),
                      // ),
                      // const SizedBox(height: 24),
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

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getClientAssignmentsStream(userId),
      builder: (context, assignmentsSnapshot) {
        final assignments = assignmentsSnapshot.data ?? [];
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final upcomingAssignments =
            assignments.where((assignment) {
              if (assignment['status'] != 'pending') return false;
              final scheduledDate = DateTime.tryParse(
                assignment['scheduledDate']?.toString() ?? '',
              );
              if (scheduledDate == null) return true;
              final scheduledDay = DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
              );
              return !scheduledDay.isBefore(startOfToday);
            }).toList()..sort((a, b) {
              final aDate =
                  DateTime.tryParse(a['scheduledDate']?.toString() ?? '') ??
                  today;
              final bDate =
                  DateTime.tryParse(b['scheduledDate']?.toString() ?? '') ??
                  today;
              return aDate.compareTo(bDate);
            });
        final pendingAssignment = upcomingAssignments.isNotEmpty
            ? upcomingAssignments.first
            : null;

        return StreamBuilder<WorkoutSession?>(
          stream: program != null
              ? DatabaseService().getNextWorkoutStream(userId, program.id)
              : Stream.value(null),
          builder: (context, workoutSnapshot) {
            final workout = workoutSnapshot.data;

            // Priority: 1. Direct Assignment, 2. Program Workout, 3. Empty State
            final bool hasContent =
                pendingAssignment != null || workout != null;

            if (!hasContent) {
              return _buildEmptyWorkoutState();
            }

            final title = pendingAssignment != null
                ? pendingAssignment['workoutTitle']
                : (workout?.title ?? "Full Body Strength");

            final duration = pendingAssignment != null
                ? "Custom"
                : (workout?.totalDuration ?? "45 min");

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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 160,
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
                            color: pendingAssignment != null
                                ? const Color(0xFFB9FF66)
                                : const Color(0xFFFBECE1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pendingAssignment != null
                                ? 'ASSIGNED: ${pendingAssignment['scheduledDate'] != null ? (pendingAssignment['scheduledDate'] as String).split('T').first : 'TODAY'}'
                                : '12 WEEK PLAN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: pendingAssignment != null
                                  ? Colors.black
                                  : const Color(0xFFC76F4B),
                              letterSpacing: 0.5,
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
                          title,
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
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppTheme.textMedium,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'High Intensity',
                              style: TextStyle(
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
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (pendingAssignment != null) {
                                _openAssignedWorkout(pendingAssignment);
                              } else {
                                setState(() => _currentIndex = 1);
                              }
                            },
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            label: Text(
                              pendingAssignment != null
                                  ? 'Start Workout'
                                  : 'Home Workout',
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: const Color(0xFFD4847A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
          },
        );
      },
    );
  }

  Future<void> _openAssignedWorkout(Map<String, dynamic> assignment) async {
    final title = assignment['workoutTitle']?.toString() ?? 'Workout';
    final driveUrl = assignment['driveUrl']?.toString() ?? '';
    final sourceType = assignment['sourceType']?.toString() ?? 'google_drive';

    Widget screen;
    if (sourceType == 'youtube') {
      final workout = Map<String, dynamic>.from(
        assignment['youtubeWorkout'] as Map? ??
            <String, dynamic>{
              '`': title,
              'Training Video': driveUrl,
              'NOTES': assignment['notes']?.toString() ?? '',
            },
      );
      screen = ActiveWorkoutScreen(
        workout: workout,
        assignmentId: assignment['id']?.toString(),
      );
    } else {
      String? folderId;
      if (driveUrl.contains('/folders/')) {
        folderId = driveUrl.split('/folders/').last.split('?').first;
      }
      screen = ExerciseDetailScreen(
        folderName: title,
        folderId: folderId,
        directVideoUrl: folderId == null ? driveUrl : null,
        assignmentId: assignment['id']?.toString(),
        directExercise: assignment['driveWorkout'] is Map
            ? ExerciseModel.fromMap(
                Map<String, dynamic>.from(assignment['driveWorkout'] as Map),
              )
            : null,
      );
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    await _refreshWorkoutProgress();
  }

  Widget _buildEmptyWorkoutState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rest & Recover',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "No workouts assigned for today. Use this time to focus on mobility and recovery!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() => _currentIndex = 1);
            },
            child: const Text(
              'View All Workouts',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryGrid(
    UserModel? user,
    WorkoutProgressSnapshot? progress,
  ) {
    final workoutCount = progress?.completedWorkouts ?? 0;
    final weeklyCount = progress?.weeklyCompletedWorkouts ?? 0;
    final currentWeight = user?.weight ?? '0';
    final weightUnit = user?.weightUnit ?? 'lbs';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.fitness_center_rounded,
                value: '$workoutCount',
                subtitle: 'Total Workouts',
                pillText: '↑ $weeklyCount this week',
                pillColor: const Color(0xFF2EB87D),
                pillBgColor: const Color(0xFFE6F5E9),
                assetsImage: 'assets/home/firstCard.png',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.trending_up_rounded,
                value: '$currentWeight $weightUnit',
                subtitle: 'Current Weight',
                pillText: 'Goal: ${user?.fitnessGoal ?? 'Keep going'}',
                pillColor: const Color(0xFFD4847A),
                pillBgColor: const Color(0xFFFDF2F0),
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
                value: '${_streak.currentStreak} days',
                subtitle: 'Current Streak',
                pillText: 'Best: ${_streak.longestStreak} days',
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
                value: '${_fitnessScore.round()}%',
                subtitle: 'Fitness Score',
                pillText: _fitnessScore > 80
                    ? 'Elite Level'
                    : 'Getting Stronger',
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

  Widget _buildWeightProgressCard(
    UserModel? user,
    WorkoutProgressSnapshot? progress,
  ) {
    final uid = AuthService().currentUser?.uid ?? '';
    final currentWeight = double.tryParse(user?.weight ?? '0') ?? 0;
    final weightUnit = user?.weightUnit ?? 'kg';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBECE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.monitor_weight_rounded,
                      color: Color(0xFFC88282),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Weight Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showLogWeightSheet(
                  context,
                  uid,
                  currentWeight,
                  weightUnit,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC88282),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Log',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currentWeight > 0
                ? 'Current: ${currentWeight.toStringAsFixed(1)} $weightUnit'
                : 'Log your weight to start tracking',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          // Chart area
          SizedBox(
            height: 200,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getWeightLogsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFC88282),
                      ),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return _buildEmptyWeightGraph();
                }

                return _buildWeightChart(logs, weightUnit);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> logs, String unit) {
    final List<FlSpot> spots = [];
    final List<String> labels = [];
    double minWeight = double.infinity;
    double maxWeight = double.negativeInfinity;

    for (int i = 0; i < logs.length; i++) {
      final weight = (logs[i]['weight'] as num?)?.toDouble() ?? 0;
      final loggedAt = DateTime.tryParse(logs[i]['loggedAt'] ?? '');

      spots.add(FlSpot(i.toDouble(), weight));

      if (loggedAt != null) {
        labels.add('${loggedAt.day}/${loggedAt.month}');
      } else {
        labels.add('${i + 1}');
      }

      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
    }

    final yPadding = ((maxWeight - minWeight) * 0.3).clamp(2.0, 20.0);
    final double chartMinY = (minWeight - yPadding).clamp(0, minWeight);
    final double chartMaxY = maxWeight + yPadding;
    final double yInterval = ((chartMaxY - chartMinY) / 4).clamp(1, 100);

    final firstWeight = spots.first.y;
    final lastWeight = spots.last.y;
    final weightChange = lastWeight - firstWeight;
    final changeSign = weightChange >= 0 ? '+' : '';
    final changeColor = weightChange <= 0
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Column(
      children: [
        if (spots.length >= 2) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  weightChange <= 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: changeColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$changeSign${weightChange.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (spots.length - 1).toDouble().clamp(1, 100),
              minY: chartMinY,
              maxY: chartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.textLight.withOpacity(0.12),
                  strokeWidth: 1,
                  dashArray: [6, 4],
                ),
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
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length)
                        return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          labels[index],
                          style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: yInterval,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.x.toInt() < labels.length
                          ? labels[spot.x.toInt()]
                          : '';
                      return LineTooltipItem(
                        '$label\n${spot.y.toStringAsFixed(1)} $unit',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFFC88282),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isLast = index == spots.length - 1;
                      return FlDotCirclePainter(
                        radius: isLast ? 6 : 4,
                        color: isLast ? const Color(0xFFC88282) : Colors.white,
                        strokeWidth: isLast ? 3 : 2.5,
                        strokeColor: const Color(0xFFC88282),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFC88282).withOpacity(0.25),
                        const Color(0xFFC88282).withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWeightGraph() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFBECE8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: Color(0xFFC88282),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No weight data yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Log" to record your first weight',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogWeightSheet(
    BuildContext context,
    String userId,
    double currentWeight,
    String unit,
  ) {
    final controller = TextEditingController(
      text: currentWeight > 0 ? currentWeight.toStringAsFixed(1) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Log Your Weight',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current weight in $unit',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    suffixText: unit,
                    suffixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMedium,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F5F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final weight = double.tryParse(controller.text.trim());
                      if (weight == null || weight <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Enter a valid weight')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await DatabaseService().saveWeightEntry(
                          userId: userId,
                          weight: weight,
                          unit: unit,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Weight logged: ${weight.toStringAsFixed(1)} $unit',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC88282),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Weight',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThisWeeksWorkouts(List<Map<String, dynamic>> assignments) {
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
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: assignments.isEmpty
              ? _buildEmptyAssignmentsState()
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    final date =
                        DateTime.tryParse(assignment['scheduledDate'] ?? '') ??
                        DateTime.now();
                    final dayLabel = index == 0 ? 'Next' : 'Upcoming';

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildHorizontalWorkoutCard(
                        day: '$dayLabel (${date.day}/${date.month})',
                        title: assignment['workoutTitle'] ?? 'Workout',
                        duration: 'Custom',
                        exercises: 'Check notes',
                        driveUrl: assignment['driveUrl'] ?? '',
                      ),
                    );
                  },
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
    required String driveUrl,
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
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _ThumbnailWrapper(driveUrl: driveUrl),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAssignmentsState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: AppTheme.primary.withOpacity(0.3),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'No scheduled workouts',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CoachDetailScreen(coach: coaches[index]),
                        ),
                      );
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
                color: _state == 'success'
                    ? const Color(0xFF2EB87D)
                    : const Color(0xFFD4847A),
                borderRadius: BorderRadius.circular(_state == 'idle' ? 16 : 28),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_state == 'success'
                                ? const Color(0xFF2EB87D)
                                : const Color(0xFFD4847A))
                            .withOpacity(0.4),
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
              'Home Workout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      );
    } else if (_state == 'loading') {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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

class _ThumbnailWrapper extends StatefulWidget {
  final String driveUrl;
  const _ThumbnailWrapper({required this.driveUrl});

  @override
  State<_ThumbnailWrapper> createState() => _ThumbnailWrapperState();
}

class _ThumbnailWrapperState extends State<_ThumbnailWrapper> {
  String? _thumbnailUrl;
  bool _loading = true;
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  void _initThumbnail() async {
    if (widget.driveUrl.isEmpty) return;

    String? thumbToUse;
    try {
      if (widget.driveUrl.contains('/folders/')) {
        final folderId = widget.driveUrl
            .split('/folders/')
            .last
            .split('?')
            .first;
        final exercises = await _driveService.fetchFolderVideos(folderId);
        if (exercises.isNotEmpty) {
          thumbToUse = exercises.last.thumbnailUrl;
        }
      } else {
        String? fileId;
        if (widget.driveUrl.contains('/file/d/')) {
          fileId = widget.driveUrl.split('/file/d/').last.split('/').first;
        } else if (widget.driveUrl.contains('id=')) {
          fileId = widget.driveUrl.split('id=').last.split('&').first;
        }

        if (fileId != null) {
          final meta = await _driveService.fetchFileMetadata(fileId);
          thumbToUse = meta['thumbnailUrl'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching thumbnail: $e');
    }

    if (mounted) {
      setState(() {
        _thumbnailUrl = thumbToUse;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 120,
        color: AppTheme.primary.withOpacity(0.05),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
      );
    }

    if (_thumbnailUrl == null) {
      return Container(
        height: 120,
        color: AppTheme.primary.withOpacity(0.05),
        child: const Icon(
          Icons.play_circle_fill,
          color: AppTheme.primary,
          size: 40,
        ),
      );
    }

    return Image.network(
      _thumbnailUrl!,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120,
        color: AppTheme.primary.withOpacity(0.05),
        child: const Icon(
          Icons.play_circle_fill,
          color: AppTheme.primary,
          size: 40,
        ),
      ),
    );
  }
}
