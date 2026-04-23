import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../constants/app_theme.dart';
import '../../models/workout_models.dart';
import '../../services/google_drive_service.dart';

enum _RestPhase { nextSet, exerciseComplete }

/// Screen that shows exercise videos inside a specific Google Drive folder.
class ExerciseDetailScreen extends StatefulWidget {
  final String folderName;
  final String? folderId;

  const ExerciseDetailScreen({
    super.key,
    required this.folderName,
    this.folderId,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {
  static const Color _screenBackground = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1B1B1F);
  static const Color _surfaceAltColor = Color(0xFF232329);
  static const Color _surfaceStrongColor = Color(0xFF2C2D34);
  static const Color _borderColor = Color(0xFF35363E);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFFD1D2D7);
  static const Color _textMuted = Color(0xFF868893);

  bool _isLoading = true;
  bool _isTransitioningExercise = false;
  String? _error;
  List<ExerciseModel> _exercises = [];
  List<int> _completedSets = [];
  int _currentIndex = 0;
  final GoogleDriveService _driveService = GoogleDriveService();
  final _ExerciseVideoCache _globalCache = _ExerciseVideoCache();

  bool _isResting = false;
  int _remainingRestSeconds = 0;
  int _activeRestDuration = 0;
  Timer? _restTimer;
  _RestPhase? _restPhase;
  int _videoLoadingProgress = 0;
  String _videoLoadingStatus = 'Fetch This Video Now';
  bool _isCurrentVideoCached = false;
  String? _videoErrorMessage;

  // Track download status for the list
  final Map<String, int> _downloadProgress = {};
  final Set<String> _cachedExerciseIds = {};

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _configureSlideAnimation(isForward: true);
    _loadExercises();
    _checkInitialCacheStatus();
  }

  @override
  void dispose() {
    _driveService.dispose();
    _globalCache.dispose();
    _slideCtrl.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  ExerciseModel get _currentExercise => _exercises[_currentIndex];

  bool get _hasPreviousExercise => _currentIndex > 0;
  bool get _hasNextExercise => _currentIndex < _exercises.length - 1;
  bool get _isBusy => _isResting || _isTransitioningExercise;

  Future<void> _checkInitialCacheStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPathsRaw = prefs.getString(_ExerciseVideoCache._prefsKey);
    if (savedPathsRaw != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedPathsRaw);
      if (mounted) {
        setState(() {
          _cachedExerciseIds.addAll(decoded.keys);
        });
      }
    }
  }

  void _startVideoLoading({required bool shouldLoad}) {
    if (!shouldLoad) {
      _isTransitioningExercise = false;
      _videoLoadingProgress = 0;
      _videoLoadingStatus = '';
      _isCurrentVideoCached = false;
      _videoErrorMessage = null;
      return;
    }

    _isTransitioningExercise = true;
    _videoLoadingProgress = 0;
    _videoLoadingStatus = 'Fetch This Video Now';
    _isCurrentVideoCached = false;
    _videoErrorMessage = null;

    // Auto-pre-fetch next video when one starts loading
    if (_hasNextExercise) {
      _preFetchVideo(_currentIndex + 1);
    }
  }

  Future<void> _preFetchVideo(int index) async {
    if (index < 0 || index >= _exercises.length) return;
    final exercise = _exercises[index];
    if (exercise.videoUrl == null || _cachedExerciseIds.contains(exercise.id)) return;

    try {
      await _globalCache.getOrDownloadVideo(
        exerciseId: exercise.id,
        videoUrl: exercise.videoUrl!,
        onProgress: (progress, status, {required fromCache}) {
          if (!mounted) return;
          setState(() {
            _downloadProgress[exercise.id] = progress;
            if (fromCache || progress >= 100) {
              _cachedExerciseIds.add(exercise.id);
            }
          });
        },
      );
    } catch (e) {
      debugPrint('Pre-fetch failed for ${exercise.name}: $e');
    }
  }

  void _handleVideoLoadingProgress(
    int progress,
    String status, {
    required bool fromCache,
  }) {
    if (!mounted) return;

    setState(() {
      _videoLoadingProgress = progress.clamp(0, 100);
      _videoLoadingStatus = status;
      _isCurrentVideoCached = fromCache;
      if (fromCache || progress >= 100) {
        _cachedExerciseIds.add(_currentExercise.id);
      }
    });
  }

  void _configureSlideAnimation({required bool isForward}) {
    _slideAnim = Tween<Offset>(
      begin: Offset(isForward ? 0.14 : -0.14, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  void _playSlide({required bool isForward}) {
    _configureSlideAnimation(isForward: isForward);
    _slideCtrl.forward(from: 0);
  }

  int _completedSetCountFor(ExerciseModel exercise) {
    if (_completedSets.isEmpty) return 0;
    return _completedSets[_currentIndex].clamp(0, exercise.sets);
  }

  bool _isExerciseComplete(ExerciseModel exercise) {
    return _completedSetCountFor(exercise) >= exercise.sets;
  }

  int _activeSetNumber(ExerciseModel exercise) {
    if (_isExerciseComplete(exercise)) return exercise.sets;
    return _completedSetCountFor(exercise) + 1;
  }

  String _mainActionLabel(ExerciseModel exercise) {
    if (_isTransitioningExercise) return 'Loading Exercise';
    if (_isResting) return 'Resting';
    if (_isExerciseComplete(exercise)) {
      return _hasNextExercise ? 'Next Exercise' : 'Finish Workout';
    }
    return 'Complete Set ${_activeSetNumber(exercise)}';
  }

  IconData _mainActionIcon(ExerciseModel exercise) {
    if (_isTransitioningExercise) return Icons.hourglass_top_rounded;
    if (_isResting) return Icons.timer_outlined;
    if (_isExerciseComplete(exercise)) return Icons.skip_next_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Future<void> _loadExercises() async {
    if (widget.folderId == null) {
      debugPrint('Error: folderId is null for category "${widget.folderName}"');
      setState(() {
        _error =
            'No folder ID found for "${widget.folderName}". This can happen if the folders were not fully imported. Please try clicking the refresh icon on the previous screen.';
        _isLoading = false;
      });
      return;
    }

    debugPrint(
      'Loading exercises for folder: ${widget.folderName} (ID: ${widget.folderId})',
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_exercises_${widget.folderId}';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        debugPrint('Loading exercises from cache for ${widget.folderName}');
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          final cachedExercises = decoded
              .map((item) => ExerciseModel.fromMap(item))
              .toList();
          if (cachedExercises.isNotEmpty) {
            setState(() {
              _applyLoadedExercises(cachedExercises);
            });
            _playSlide(isForward: true);
            return;
          }
        } catch (e) {
          debugPrint('Error decoding cached exercises: $e');
        }
      }

      debugPrint('Fetching exercises from Drive for ${widget.folderName}');
      final fetched = await _driveService.fetchFolderVideos(widget.folderId!);

      if (fetched.isEmpty) {
        throw 'No video files found in the "${widget.folderName}" folder (ID: ${widget.folderId}). Please check if the videos are inside sub-folders.';
      }

      final encoded = jsonEncode(fetched.map((e) => e.toMap()).toList());
      await prefs.setString(cacheKey, encoded);

      setState(() {
        _applyLoadedExercises(fetched);
      });
      _playSlide(isForward: true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyLoadedExercises(List<ExerciseModel> exercises) {
    _exercises = exercises;
    _completedSets = List<int>.filled(exercises.length, 0);
    _currentIndex = 0;
    _isLoading = false;
    _startVideoLoading(shouldLoad: exercises.first.videoUrl != null);
    _isResting = false;
    _remainingRestSeconds = 0;
    _activeRestDuration = 0;
    _restPhase = null;
  }

  void _completeSet() {
    if (_isBusy || _exercises.isEmpty) return;

    final exercise = _currentExercise;
    if (_isExerciseComplete(exercise)) {
      _goToNextExerciseOrFinish();
      return;
    }

    final isFinalSet = _completedSetCountFor(exercise) + 1 >= exercise.sets;
    if (exercise.restSeconds > 0) {
      _startRest(
        exercise.restSeconds,
        phase: isFinalSet ? _RestPhase.exerciseComplete : _RestPhase.nextSet,
      );
      return;
    }

    _applyCompletedSet();
  }

  void _startRest(int seconds, {required _RestPhase phase}) {
    _restTimer?.cancel();

    if (seconds <= 0) {
      _applyCompletedSet();
      return;
    }

    setState(() {
      _isResting = true;
      _remainingRestSeconds = seconds;
      _activeRestDuration = seconds;
      _restPhase = phase;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 1) {
        setState(() => _remainingRestSeconds--);
      } else {
        timer.cancel();
        _finishRest();
      }
    });
  }

  void _finishRest() {
    _restTimer?.cancel();
    _applyCompletedSet();
  }

  Future<void> _incrementFitnessScore() async {
    final prefs = await SharedPreferences.getInstance();
    final currentScore = prefs.getDouble('fitness_score') ?? 0.0;
    // Increase score by 5 per completed exercise, capped at 100 for now
    final newScore = (currentScore + 5).clamp(0.0, 100.0);
    await prefs.setDouble('fitness_score', newScore);
  }

  void _applyCompletedSet() {
    if (_exercises.isEmpty) return;

    final exercise = _currentExercise;
    final nextCompleted = (_completedSetCountFor(exercise) + 1).clamp(
      0,
      exercise.sets,
    );

    if (nextCompleted == exercise.sets && _completedSetCountFor(exercise) < exercise.sets) {
      // First time completing all sets for this exercise
      _incrementFitnessScore();
    }

    setState(() {
      _completedSets[_currentIndex] = nextCompleted;
      _isResting = false;
      _remainingRestSeconds = 0;
      _activeRestDuration = 0;
      _restPhase = null;
    });
  }

  void _skipRest() {
    if (!_isResting) return;
    _finishRest();
  }

  void _goToNextExerciseOrFinish() {
    if (_hasNextExercise) {
      _goToExercise(_currentIndex + 1);
      return;
    }
    _showCompleteDialog();
  }

  void _goToPreviousExercise() {
    if (!_hasPreviousExercise || _isBusy) return;
    _goToExercise(_currentIndex - 1);
  }

  void _skipExercise() {
    if (_isBusy) return;

    if (_hasNextExercise) {
      _goToExercise(_currentIndex + 1);
      return;
    }

    _showCompleteDialog();
  }

  void _goToExercise(int newIndex) {
    if (newIndex < 0 ||
        newIndex >= _exercises.length ||
        newIndex == _currentIndex) {
      return;
    }

    final isForward = newIndex > _currentIndex;
    final nextExercise = _exercises[newIndex];
    _restTimer?.cancel();

    setState(() {
      _currentIndex = newIndex;
      _isResting = false;
      _remainingRestSeconds = 0;
      _activeRestDuration = 0;
      _restPhase = null;
      _startVideoLoading(shouldLoad: nextExercise.videoUrl != null);
    });

    _playSlide(isForward: isForward);
  }

  void _handleVideoReady() {
    if (!mounted) return;
    setState(() {
      _isTransitioningExercise = false;
      _videoLoadingProgress = 100;
      _videoLoadingStatus = _isCurrentVideoCached
          ? 'Saved In SharedPreferences'
          : 'Video Ready';
    });
  }

  void _handleVideoError(String message) {
    if (!mounted) return;
    setState(() {
      _isTransitioningExercise = false;
      _videoErrorMessage = message;
      _videoLoadingStatus = message;
    });
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceAltColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Workout Complete!',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Great job! You finished all exercises in this category.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    if (_isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: const Scaffold(
          backgroundColor: _screenBackground,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: _screenBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBackButton(),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 82,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to Load Workout',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: _textPrimary,
                        minimumSize: const Size.fromHeight(58),
                      ),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentExercise = _currentExercise;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _screenBackground,
        body: Stack(
          children: [
            Column(
              children: [
                _buildVideoHero(currentExercise),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(),
                          const SizedBox(height: 10),
                          Text(
                            currentExercise.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _textPrimary,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentExercise.instruction,
                            style: const TextStyle(
                              fontSize: 15,
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatsRow(currentExercise),
                          const SizedBox(height: 20),
                          _buildSetProgress(currentExercise),
                          if (_isResting) ...[
                            const SizedBox(height: 18),
                            _buildRestCard(currentExercise),
                          ],
                          const SizedBox(height: 24),
                          _buildMainAction(currentExercise),
                          const SizedBox(height: 14),
                          _buildNavigationButtons(),
                          const SizedBox(height: 28),
                          _buildUpcomingList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              child: _buildBackButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHero(ExerciseModel exercise) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (exercise.thumbnailUrl != null)
              Image.network(
                exercise.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            if (exercise.videoUrl != null)
              _VideoPlayerHero(
                key: ValueKey(
                  '${exercise.id}_${exercise.videoUrl ?? 'novideo'}',
                ),
                exerciseId: exercise.id,
                videoUrl: exercise.videoUrl!,
                onReady: _handleVideoReady,
                onLoadingProgress: _handleVideoLoadingProgress,
                onError: _handleVideoError,
                cache: _globalCache,
              )
            else
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 88,
                  color: Colors.white24,
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xC9121212),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _isTransitioningExercise ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isTransitioningExercise,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fetch $_videoLoadingProgress%',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _videoLoadingStatus.isEmpty
                              ? 'Fetch This Video Now'
                              : _videoLoadingStatus,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isCurrentVideoCached) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Instant Replay Ready',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
          ),
          child: Text(
            widget.folderName.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const Spacer(),
        Text(
          '${_currentIndex + 1}/${_exercises.length}',
          style: const TextStyle(
            color: _textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ExerciseModel exercise) {
    return Row(
      children: [
        _buildStatCard('Sets', '${exercise.sets}'),
        const SizedBox(width: 12),
        _buildStatCard('Reps', exercise.reps),
        const SizedBox(width: 12),
        _buildStatCard('Rest', '${exercise.restSeconds}s'),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _surfaceAltColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetProgress(ExerciseModel exercise) {
    final completedSets = _completedSetCountFor(exercise);
    final activeSet = _activeSetNumber(exercise);
    final isComplete = _isExerciseComplete(exercise);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Set Progress',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                isComplete
                    ? 'Ready for next'
                    : 'Set $activeSet of ${exercise.sets}',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(exercise.sets, (index) {
              final isDone = index < completedSets;
              final isActive = index == completedSets && !isComplete;

              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(
                    right: index < exercise.sets - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primary
                        : isActive
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : _surfaceStrongColor,
                    borderRadius: BorderRadius.circular(999),
                    border: isActive
                        ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRestCard(ExerciseModel exercise) {
    final progress = 1.0 - (_remainingRestSeconds / _activeRestDuration);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _restPhase == _RestPhase.exerciseComplete
                    ? 'Exercise Complete Rest'
                    : 'Rest for next set',
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _skipRest,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_remainingRestSeconds',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'sec',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _surfaceStrongColor,
            color: AppTheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction(ExerciseModel exercise) {
    final label = _mainActionLabel(exercise);
    final icon = _mainActionIcon(exercise);
    final isDone = _isExerciseComplete(exercise);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isBusy ? null : _completeSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? _surfaceStrongColor : AppTheme.primary,
          foregroundColor: _textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canGoBack = _hasPreviousExercise && !_isBusy;
    final canSkip = !_isBusy;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canGoBack ? _goToPreviousExercise : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              disabledForegroundColor: _textMuted,
              side: BorderSide(
                color: canGoBack
                    ? _borderColor
                    : _borderColor.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: _surfaceAltColor,
            ),
            child: const Text(
              'Previous',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: canSkip ? _skipExercise : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              disabledForegroundColor: _textMuted,
              side: BorderSide(
                color: canSkip
                    ? _borderColor
                    : _borderColor.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: _surfaceAltColor,
            ),
            child: Text(
              _hasNextExercise ? 'Skip' : 'Finish',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_exercises.length, (index) {
          final exercise = _exercises[index];
          final isDone = _completedSets[index] >= exercise.sets;
          final isCurrent = index == _currentIndex;
          final completedSets = _completedSets[index].clamp(0, exercise.sets);
          final progress = _downloadProgress[exercise.id];
          final isCached = _cachedExerciseIds.contains(exercise.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent ? _surfaceAltColor : _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent
                    ? AppTheme.primary.withValues(alpha: 0.45)
                    : _borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.primary
                        : isCurrent
                        ? AppTheme.primary.withValues(alpha: 0.16)
                        : _surfaceStrongColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 18, color: _textPrimary)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.primary
                                  : _textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDone
                            ? 'Completed'
                            : '$completedSets/${exercise.sets} sets complete',
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (exercise.videoUrl != null)
                  _buildDownloadIndicator(exercise.id, progress, isCached),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDownloadIndicator(String id, int? progress, bool isCached) {
    if (isCached) {
      return const Icon(
        Icons.check_circle_outline_rounded,
        color: AppTheme.primary,
        size: 20,
      );
    }

    if (progress != null && progress < 100) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: progress / 100,
          strokeWidth: 2,
          color: AppTheme.primary,
          backgroundColor: _surfaceStrongColor,
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_for_offline_rounded, size: 22),
      color: _textMuted,
      onPressed: () {
        final index = _exercises.indexWhere((e) => e.id == id);
        if (index != -1) _preFetchVideo(index);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.36),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _VideoPlayerHero extends StatefulWidget {
  final String exerciseId;
  final String videoUrl;
  final VoidCallback? onReady;
  final void Function(int progress, String status, {required bool fromCache})?
  onLoadingProgress;
  final ValueChanged<String>? onError;
  final _ExerciseVideoCache cache;

  const _VideoPlayerHero({
    required this.exerciseId,
    required this.videoUrl,
    required this.cache,
    this.onReady,
    this.onLoadingProgress,
    this.onError,
    super.key,
  });

  @override
  State<_VideoPlayerHero> createState() => _VideoPlayerHeroState();
}

class _VideoPlayerHeroState extends State<_VideoPlayerHero> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    File? videoFile;
    var fromCache = false;

    try {
      final result = await widget.cache.getOrDownloadVideo(
        exerciseId: widget.exerciseId,
        videoUrl: widget.videoUrl,
        onProgress: (progress, status, {required fromCache}) {
          if (!mounted) return;
          widget.onLoadingProgress?.call(
            progress,
            status,
            fromCache: fromCache,
          );
        },
      );
      videoFile = result.file;
      fromCache = result.fromCache;
    } catch (error) {
      debugPrint('Video cache error: $error');
    }

    _controller = videoFile != null
        ? VideoPlayerController.file(videoFile)
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _controller!.initialize();
      if (!mounted) return;

      await _controller!
        ..setLooping(true)
        ..play();

      setState(() => _initialized = true);
      widget.onLoadingProgress?.call(
        100,
        fromCache ? 'Saved In SharedPreferences' : 'Fetched And Saved',
        fromCache: true,
      );
      widget.onReady?.call();
    } catch (error) {
      debugPrint('Video error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Video could not load.';
      });
      widget.onError?.call(_errorMessage!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}

class _CachedVideoResult {
  final File file;
  final bool fromCache;

  const _CachedVideoResult({required this.file, required this.fromCache});
}

class _ExerciseVideoCache {
  _ExerciseVideoCache({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const String _prefsKey = 'cached_exercise_video_paths';

  Future<_CachedVideoResult> getOrDownloadVideo({
    required String exerciseId,
    required String videoUrl,
    required void Function(
      int progress,
      String status, {
      required bool fromCache,
    })
    onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPaths = _loadSavedPaths(prefs);
    final savedPath = savedPaths[exerciseId];

    if (savedPath != null) {
      final savedFile = File(savedPath);
      if (await savedFile.exists() && await savedFile.length() > 0) {
        onProgress(100, 'Fetch 100% - Instant Play', fromCache: true);
        return _CachedVideoResult(file: savedFile, fromCache: true);
      }

      savedPaths.remove(exerciseId);
      await _savePaths(prefs, savedPaths);
    }

    final file = await _videoFileFor(exerciseId);
    if (await file.exists() && await file.length() > 0) {
      savedPaths[exerciseId] = file.path;
      await _savePaths(prefs, savedPaths);
      onProgress(100, 'Fetch 100% - Instant Play', fromCache: true);
      return _CachedVideoResult(file: file, fromCache: true);
    }

    onProgress(0, 'Fetch This Video Now', fromCache: false);
    await file.parent.create(recursive: true);

    final tempFile = File('${file.path}.download');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final response = await _client.send(
      http.Request('GET', Uri.parse(videoUrl)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch video (${response.statusCode})');
    }

    final sink = tempFile.openWrite();
    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    var fallbackProgress = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          final progress = ((receivedBytes / totalBytes) * 100).round().clamp(
            0,
            100,
          );
          onProgress(progress, 'Fetch This Video Now', fromCache: false);
        } else {
          fallbackProgress = (fallbackProgress + 4).clamp(0, 100);
          onProgress(
            fallbackProgress,
            'Fetch This Video Now',
            fromCache: false,
          );
        }
      }
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      await sink.close();
    }

    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);

    savedPaths[exerciseId] = file.path;
    await _savePaths(prefs, savedPaths);
    onProgress(100, 'Saved In SharedPreferences', fromCache: true);
    return _CachedVideoResult(file: file, fromCache: false);
  }

  Future<File> _videoFileFor(String exerciseId) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory('${directory.path}/exercise_video_cache');
    return File('${cacheDirectory.path}/${_sanitize(exerciseId)}.mp4');
  }

  Map<String, String> _loadSavedPaths(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _savePaths(
    SharedPreferences prefs,
    Map<String, String> paths,
  ) async {
    await prefs.setString(_prefsKey, jsonEncode(paths));
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  void dispose() {
    _client.close();
  }
}
