import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/workout_progress_service.dart';
import 'workout_complete_screen.dart';

class WorkoutTestingScreen extends StatefulWidget {
  const WorkoutTestingScreen({super.key});

  @override
  State<WorkoutTestingScreen> createState() => _WorkoutTestingScreenState();
}

class _WorkoutTestingScreenState extends State<WorkoutTestingScreen> {
  Map<String, List<dynamic>> _categoryGroups = {};
  List<String> _categories = [];
  bool _isLoading = true;
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      setState(() => _debugInfo = "Loading JSON...");
      final String response = await rootBundle.loadString(
        'assets/data/workout.json',
      );
      final List<dynamic> data = json.decode(response);

      Map<String, List<dynamic>> groups = {};
      String currentCategory = "GENERAL";
      List<String> categoryNames = [];

      int itemsProcessed = 0;
      int categoriesFound = 0;

      for (var item in data) {
        itemsProcessed++;
        // Use backtick as key, or fallback to first key if backtick doesn't exist
        String name =
            (item['`']?.toString() ?? item.values.first?.toString() ?? '')
                .trim();
        String video = (item['Training Video']?.toString() ?? '').trim();

        // Lenient category detection:
        // If it has no video link/name AND has a name, it's likely a category header
        bool isCategory = video.isEmpty && name.isNotEmpty;

        if (isCategory) {
          currentCategory = name;
          categoriesFound++;
          if (!categoryNames.contains(currentCategory)) {
            categoryNames.add(currentCategory);
          }
          groups[currentCategory] = [];
        } else if (name.isNotEmpty) {
          if (!groups.containsKey(currentCategory)) {
            groups[currentCategory] = [];
            if (!categoryNames.contains(currentCategory)) {
              categoryNames.add(currentCategory);
            }
          }
          groups[currentCategory]!.add(item);
        }
      }

      setState(() {
        _categoryGroups = groups;
        _categories = categoryNames;
        _isLoading = false;
        _debugInfo =
            "Processed $itemsProcessed items, found $categoriesFound categories.";
      });
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      setState(() {
        _isLoading = false;
        _debugInfo = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        title: Text(
          'GYMLAB',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No categories found",
                    style: TextStyle(color: AppTheme.textDark, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _debugInfo,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final exerciseCount = _categoryGroups[category]?.length ?? 0;

                if (exerciseCount == 0) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryExerciseListScreen(
                          categoryName: category,
                          exercises: _categoryGroups[category]!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.divider, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.textDark.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.fitness_center,
                            size: 100,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category,
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$exerciseCount Exercises Available',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 24,
                          top: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.textLight.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CategoryExerciseListScreen extends StatelessWidget {
  final String categoryName;
  final List<dynamic> exercises;

  const CategoryExerciseListScreen({
    super.key,
    required this.categoryName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final workout = exercises[index];
          final String name = workout['`'] ?? 'Unknown';
          final String videoUrl = workout['Training Video'] ?? '';
          final bool hasVideo =
              videoUrl.isNotEmpty && videoUrl.startsWith('http');

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: hasVideo
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : AppTheme.divider,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textDark.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  title: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          hasVideo
                              ? Icons.play_circle_fill
                              : Icons.videocam_off_outlined,
                          size: 18,
                          color: hasVideo
                              ? AppTheme.primary
                              : AppTheme.textLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasVideo
                              ? 'Tutorial Available'
                              : 'No Video Available',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: hasVideo
                                ? AppTheme.primary
                                : AppTheme.textLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: hasVideo
                      ? IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppTheme.textLight,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  url: videoUrl,
                                  title: name,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
                if (hasVideo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActiveWorkoutScreen(workout: workout),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textOnDark,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'START WORKOUT',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workout;
  final String? assignmentId;
  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.assignmentId,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late YoutubePlayerController _controller;
  Timer? _restTimer;
  bool _isResting = false;
  int _remainingRestMillis = 0;
  int _activeRestMillis = 0;
  DateTime? _restEndsAt;
  int _completedSets = 0;
  bool _isCompletingWorkout = false;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(
      _workoutValue('Training Video', 'trainingVideo'),
    );

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        disableDragSeek: false,
        loop: true,
        isLive: false,
        forceHD: false,
        enableCaption: true,
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube() async {
    final url = _workoutValue('Training Video', 'trainingVideo');
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _workoutValue(String primaryKey, [String? fallbackKey]) {
    final primaryValue = widget.workout[primaryKey]?.toString();
    if (primaryValue != null && primaryValue.isNotEmpty) {
      return primaryValue;
    }

    if (fallbackKey == null) return '';
    return widget.workout[fallbackKey]?.toString() ?? '';
  }

  int _parseNumber(String primaryKey, int fallback, [String? fallbackKey]) {
    final value = _workoutValue(primaryKey, fallbackKey);
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }

  int get _totalSets =>
      _parseNumber('WORKING SETS', 3, 'workingSets').clamp(1, 12).toInt();
  int get _restSeconds =>
      _parseNumber('REST', 90, 'rest').clamp(0, 600).toInt();

  bool get _isWorkoutComplete => _completedSets >= _totalSets;

  void _startRest() {
    if (_restSeconds <= 0) {
      setState(() {
        _completedSets = (_completedSets + 1).clamp(0, _totalSets).toInt();
      });
      return;
    }

    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _activeRestMillis = _restSeconds * 1000;
      _remainingRestMillis = _restSeconds * 1000;
      _restEndsAt = DateTime.now().add(Duration(seconds: _restSeconds));
    });

    _restTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = _restEndsAt!
          .difference(DateTime.now())
          .inMilliseconds
          .clamp(0, _activeRestMillis);

      if (remaining <= 0) {
        timer.cancel();
        _finishRest();
        return;
      }

      setState(() {
        _remainingRestMillis = remaining;
      });
    });
  }

  void _completeSet() {
    if (_isResting || _isWorkoutComplete) return;
    final nextCompleted = (_completedSets + 1).clamp(0, _totalSets).toInt();
    if (nextCompleted >= _totalSets) {
      setState(() => _completedSets = nextCompleted);
      return;
    }
    _startRest();
  }

  void _finishRest() {
    _restTimer?.cancel();
    setState(() {
      _completedSets = (_completedSets + 1).clamp(0, _totalSets).toInt();
      _isResting = false;
      _remainingRestMillis = 0;
      _activeRestMillis = 0;
      _restEndsAt = null;
    });
  }

  Future<void> _finishWorkout() async {
    if (_isCompletingWorkout) return;
    _restTimer?.cancel();

    setState(() => _isCompletingWorkout = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = _workoutValue('`', 'name').isEmpty
        ? 'Workout'
        : _workoutValue('`', 'name');

    if (uid != null) {
      await DatabaseService().markAssignmentAsCompleted(
        uid,
        name,
        assignmentId: widget.assignmentId,
      );
    }

    final progress = await WorkoutProgressService().recordWorkoutCompletion(
      scoreIncrement: 10,
      completionId: widget.assignmentId,
    );

    if (!mounted) return;
    setState(() => _isCompletingWorkout = false);

    final action = await Navigator.of(context).push<WorkoutCompletionAction>(
      MaterialPageRoute(
        builder: (_) => WorkoutCompleteScreen(
          summary: WorkoutCompletionSummary(
            title: 'Workout Complete!',
            subtitle:
                'You finished $name. Your fitness score is updated from your real progress.',
            durationMinutes: ((_totalSets * 45 + _restSeconds) / 60)
                .ceil()
                .clamp(5, 60),
            exerciseCount: 1,
            weeklyCompleted: progress.weeklyCompletedWorkouts,
            weeklyGoal: WorkoutProgressService.weeklyGoal,
            streakDays: 1,
            scoreAdded: 0,
            totalScore: progress.fitnessScore.round(),
          ),
        ),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final name = _workoutValue('`', 'name').isEmpty
        ? 'Workout'
        : _workoutValue('`', 'name');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isResting || _isWorkoutComplete
                    ? null
                    : _completeSet,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isWorkoutComplete
                      ? 'SETS COMPLETE'
                      : 'COMPLETE SET ${_completedSets + 1}',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textOnDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 118,
              child: OutlinedButton(
                onPressed: _finishWorkout,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.4),
                ),
                child: const Text('FINISH'),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoCard(),
                const SizedBox(height: 10),
                _buildMetricStrip(),
                const SizedBox(height: 12),
                _buildSetProgress(),
                const SizedBox(height: 12),
                _buildTempoDetails(),
                if (_workoutValue('NOTES', 'detailedNotes').isNotEmpty)
                  _buildNotesCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isResting ? _buildRestOverlay() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _launchYouTube,
          icon: const Icon(
            Icons.open_in_new_rounded,
            color: AppTheme.primary,
            size: 16,
          ),
          label: Text(
            "Video stuck? Play in YouTube App",
            style: GoogleFonts.outfit(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetProgress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Workout Start',
                style: GoogleFonts.outfit(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$_completedSets / $_totalSets sets',
                style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_totalSets, (index) {
              final isDone = index < _completedSets;
              final isActive = index == _completedSets && !_isWorkoutComplete;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 8,
                  margin: EdgeInsets.only(
                    right: index < _totalSets - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primary
                        : isActive
                        ? AppTheme.primaryLight
                        : AppTheme.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStrip() {
    final metrics = [
      ('Sets', _totalSets.toString(), Icons.fitness_center_rounded),
      (
        'Reps',
        _workoutValue('REPS', 'reps').isEmpty
            ? '-'
            : _workoutValue('REPS', 'reps'),
        Icons.repeat_rounded,
      ),
      (
        'Tempo',
        _workoutValue('TEMPO', 'tempo').isEmpty
            ? '-'
            : _workoutValue('TEMPO', 'tempo'),
        Icons.speed_rounded,
      ),
      ('Rest', '${_restSeconds}s', Icons.timer_outlined),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: metrics.map((metric) {
          return Expanded(
            child: _buildMetricPill(
              label: metric.$1,
              value: metric.$2,
              icon: metric.$3,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoDetails() {
    final eccentric = _workoutValue('', 'eccentric');
    final concentric = _workoutValue('__1', 'concentric');
    final isometric = _workoutValue('__2', 'isometric');
    if (eccentric.isEmpty && concentric.isEmpty && isometric.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ecc $eccentric  •  Con $concentric  •  Iso $isometric',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "DETAILED INSTRUCTIONS",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _workoutValue('NOTES', 'detailedNotes'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestOverlay() {
    final progress = _activeRestMillis == 0
        ? 0.0
        : 1 - (_remainingRestMillis / _activeRestMillis);
    final seconds = (_remainingRestMillis ~/ 1000).clamp(0, 999);
    final centiseconds = ((_remainingRestMillis % 1000) ~/ 10).clamp(0, 99);

    return Container(
      key: const ValueKey('rest_overlay'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2520), Color(0xFFA6625B), Color(0xFFCDA96E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _finishRest,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textOnDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      'SET ${_completedSets + 1} DONE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.88, end: 1),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 254,
                      height: 254,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.42),
                            blurRadius: 42,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 232,
                      height: 232,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 15,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.24),
                        color: AppTheme.accentLight,
                      ),
                    ),
                    Container(
                      width: 184,
                      height: 184,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$seconds',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textDark,
                                    fontSize: 58,
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '.${centiseconds.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'SECONDS',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Text(
                'REST TIME',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Set ${_completedSets + 1} complete. Get ready for set ${_completedSets + 2}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _finishRest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('SKIP REST'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _finishWorkout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.74),
                          width: 1.4,
                        ),
                        minimumSize: const Size.fromHeight(58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('FINISH'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const VideoPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.url);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        useHybridComposition: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            color: AppTheme.primary,
            onPressed: _launchYouTube,
            tooltip: 'Open in YouTube App',
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
