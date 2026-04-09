// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../constants/app_theme.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'workout_complete_screen.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutSession session;

  const WorkoutExecutionScreen({super.key, required this.session});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen>
    with TickerProviderStateMixin {
  late WorkoutSession _session;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  bool _isResting = false;
  int _remainingRestSeconds = 0;
  int _totalRestSeconds = 0;
  Timer? _restTimer;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnim;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Safety check for empty exercises
    if (_session.exercises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This workout has no exercises yet.')),
        );
        Navigator.pop(context);
      });
    }
  }

  ExerciseModel get _currentExercise =>
      _session.exercises[_currentExerciseIndex];

  ExerciseModel? get _nextExercise {
    // Next set of same exercise
    if (_currentSetIndex < _currentExercise.sets - 1) return _currentExercise;
    // Next exercise
    if (_currentExerciseIndex < _session.exercises.length - 1) {
      return _session.exercises[_currentExerciseIndex + 1];
    }
    return null; // Last exercise last set
  }

  bool get _isLastSetOfLastExercise =>
      _currentSetIndex == _currentExercise.sets - 1 &&
      _currentExerciseIndex == _session.exercises.length - 1;

  void _startRest() {
    setState(() {
      _isResting = true;
      _remainingRestSeconds = _currentExercise.restSeconds;
      _totalRestSeconds = _currentExercise.restSeconds;
    });
    _progressController.forward(from: 0);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        setState(() => _remainingRestSeconds--);
      } else {
        _skipRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isResting = false;
      if (_currentSetIndex < _currentExercise.sets - 1) {
        _currentSetIndex++;
      } else if (_currentExerciseIndex < _session.exercises.length - 1) {
        _currentExerciseIndex++;
        _currentSetIndex = 0;
      } else {
        _finishWorkout();
        return;
      }
    });
  }

  void _previousExerciseOrSet() {
    _restTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isResting = false;
      if (_currentSetIndex > 0) {
        _currentSetIndex--;
      } else if (_currentExerciseIndex > 0) {
        _currentExerciseIndex--;
        _currentSetIndex = _session.exercises[_currentExerciseIndex].sets - 1;
      }
    });
  }

  Future<void> _finishWorkout() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // We set a timeout to ensure navigation happens even if network is slow
        await DatabaseService()
            .completeWorkout(
          userId: user.uid,
          programId: _session.programId,
          workoutId: _session.id,
          workoutTitle: _session.title,
          duration: _session.totalDuration,
          exercisesCount: _session.exercises.length,
          calories: _session.caloriesBurned,
        )
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Workout sync timed out, continuing to completion screen');
        });
      }
    } catch (e) {
      debugPrint('Error completing workout: $e');
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutCompleteScreen(
          programId: _session.programId,
          duration: _session.totalDuration,
          exercisesCount: _session.exercises.length,
          calories: _session.caloriesBurned,
        ),
      ),
    );
  }

  double get _overallProgress {
    double p = _currentExerciseIndex / _session.exercises.length;
    p += (_currentSetIndex / _currentExercise.sets) / _session.exercises.length;
    return p.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: Column(
        children: [
          _buildHeroSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopProgressBar(),
                  const SizedBox(height: 28),
                  _buildExerciseHeader(),
                  const SizedBox(height: 28),
                  _buildMetadataRow(),
                  const SizedBox(height: 36),
                  if (_isResting) _buildRestCard() else _buildSetsTracking(),
                  const SizedBox(height: 28),
                  if (!_isResting && _nextExercise != null)
                    _buildNextExercisePreview(),
                  const SizedBox(height: 36),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.36,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1F3D), Color(0xFF1A2A3A), Color(0xFF0F1117)],
            ),
          ),
          child: ClipRRect(
            child: _isResting || _currentExercise.videoUrl == null
                ? AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: _pulseAnim.value, child: child),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isResting
                              ? 'Rest & Recover 💆‍♀️'
                              : 'Demo Placeholder',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _VideoPlayerHero(videoUrl: _currentExercise.videoUrl!),
                      Container(
                        color: Colors.black.withOpacity(0.25),
                      ), // Subtle dark fade
                    ],
                  ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconChip(
                  Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Exercise ${_currentExerciseIndex + 1} of ${_session.exercises.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                _buildIconChip(Icons.flag_rounded, onTap: _finishWorkout),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconChip(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTopProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _session.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(_overallProgress * 100).toInt()}% complete',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _overallProgress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentExercise.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentExercise.instruction,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.55),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow() {
    return Row(
      children: [
        Expanded(child: _buildMetadataCard('SETS', '${_currentExercise.sets}')),
        const SizedBox(width: 12),
        Expanded(child: _buildMetadataCard('REPS', _currentExercise.reps)),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetadataCard('REST', '${_currentExercise.restSeconds}s'),
        ),
      ],
    );
  }

  Widget _buildMetadataCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.35),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Set ${_currentSetIndex + 1} of ${_currentExercise.sets}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_isLastSetOfLastExercise)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Last Set 🏁',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: List.generate(_currentExercise.sets, (index) {
            final isDone = index < _currentSetIndex;
            final isActive = index == _currentSetIndex;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 7,
                margin: EdgeInsets.only(
                  right: index == _currentExercise.sets - 1 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: isDone
                      ? const LinearGradient(
                          colors: [Color(0xFF2EDBAA), Color(0xFF2EB87D)],
                        )
                      : null,
                  color: !isDone
                      ? isActive
                            ? AppTheme.primary
                            : Colors.white.withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRestCard() {
    final restProgress = _totalRestSeconds > 0
        ? (_totalRestSeconds - _remainingRestSeconds) / _totalRestSeconds
        : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.12),
            AppTheme.accent.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          // Circular ring timer
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _RingPainter(progress: restProgress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_remainingRestSeconds}s',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'remaining',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Rest up. You\'ve earned it 💆‍♀️',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Breathe deeply. Stay focused.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows what's coming next (next set or next exercise)
  Widget _buildNextExercisePreview() {
    final next = _nextExercise;
    if (next == null) return const SizedBox.shrink();

    final isNextSet = next.name == _currentExercise.name;
    final label = isNextSet ? 'Next: Set ${_currentSetIndex + 2}' : 'Up next';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.skip_next_rounded,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.35),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  next.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!isNextSet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${next.sets} sets',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isFinish = _isLastSetOfLastExercise && !_isResting;
    final buttonText = _isResting
        ? 'Skip Rest'
        : isFinish
        ? 'Finish Workout 🏆'
        : 'Complete Set ${_currentSetIndex + 1}';

    final buttonGradient = _isResting
        ? LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.08),
            ],
          )
        : isFinish
        ? const LinearGradient(colors: [AppTheme.accent, AppTheme.primary])
        : AppTheme.primaryGradient;

    return Column(
      children: [
        GestureDetector(
          onTap: _isResting
              ? _skipRest
              : (isFinish ? _finishWorkout : _startRest),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isResting ? [] : [],
            ),
            child: Center(
              child: _isFinishing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isResting)
                          Icon(
                            isFinish
                                ? Icons.emoji_events_rounded
                                : Icons.check_rounded,
                            size: 24,
                            color: isFinish ? Colors.white : Colors.black87,
                          ),
                        if (!_isResting) const SizedBox(width: 10),
                        Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _isResting
                                ? Colors.white60
                                : (isFinish ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (!_isResting) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  Icons.arrow_back_rounded,
                  'Previous',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryButton(
                  Icons.skip_next_rounded,
                  'Skip Set',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSecondaryButton(IconData icon, String text) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: text == 'Skip Set'
            ? _skipRest
            : (text == 'Previous' ? _previousExerciseOrSet : () {}),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the circular rest ring
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _VideoPlayerHero extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerHero({required this.videoUrl});

  @override
  State<_VideoPlayerHero> createState() => _VideoPlayerHeroState();
}

class _VideoPlayerHeroState extends State<_VideoPlayerHero> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _VideoPlayerHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initVideo();
    }
  }

  void _initVideo() {
    _initialized = false;
    final isNetwork = widget.videoUrl.startsWith('http');

    if (isNetwork) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    } else {
      _controller = VideoPlayerController.asset(widget.videoUrl);
    }

    _controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
            _controller.setLooping(true);
            _controller.setVolume(0); // silent
            _controller.play();
          }
        })
        .catchError((error) {
          debugPrint('Error initializing video: $error');
          if (mounted) {
            setState(() {
              _initialized = false; // Will show fallback UI
            });
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
