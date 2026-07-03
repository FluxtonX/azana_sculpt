import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../models/workout_models.dart';
import 'exercise_detail_screen.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'workout_complete_screen.dart';
import '../../services/google_drive_service.dart';
import 'workout_testing_screen.dart';

class ExerciseFetchScreen extends StatefulWidget {
  final String driveUrl;
  final VoidCallback? onProgressUpdated;
  final VoidCallback? onNavigateHome;
  final VoidCallback? onNavigateProgress;

  const ExerciseFetchScreen({
    super.key,
    required this.driveUrl,
    this.onProgressUpdated,
    this.onNavigateHome,
    this.onNavigateProgress,
  });

  @override
  State<ExerciseFetchScreen> createState() => _ExerciseFetchScreenState();
}

class _ExerciseFetchScreenState extends State<ExerciseFetchScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getClientAssignmentsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }

                final assignments = snapshot.data ?? [];

                if (assignments.isEmpty) {
                  return _buildEmptyState();
                }

                _listAnimationController.forward();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return AnimatedBuilder(
                      animation: _listAnimationController,
                      builder: (context, child) {
                        final delay = index * 0.1;
                        final start = delay.clamp(0.0, 1.0);
                        final end = (delay + 0.5).clamp(0.0, 1.0);

                        final opacity = CurvedAnimation(
                          parent: _listAnimationController,
                          curve: Interval(start, end, curve: Curves.easeOut),
                        ).value;

                        final slide = CurvedAnimation(
                          parent: _listAnimationController,
                          curve: Interval(
                            start,
                            end,
                            curve: Curves.easeOutBack,
                          ),
                        ).value;

                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(0, 50 * (1 - slide)),
                            child: child,
                          ),
                        );
                      },
                      child: _AssignmentVideoCard(
                        assignment: assignment,
                        onProgressUpdated: widget.onProgressUpdated,
                        onNavigateHome: widget.onNavigateHome,
                        onNavigateProgress: widget.onNavigateProgress,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4847A).withOpacity(0.15),
            const Color(0xFFCDA96E).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4847A).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Color(0xFFD4847A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Workouts',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                'Crush your daily targets',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 80,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No assigned workout',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your coach hasn\'t assigned any workouts for today yet. Keep an eye out!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AssignmentVideoCard extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback? onProgressUpdated;
  final VoidCallback? onNavigateHome;
  final VoidCallback? onNavigateProgress;

  const _AssignmentVideoCard({
    required this.assignment,
    this.onProgressUpdated,
    this.onNavigateHome,
    this.onNavigateProgress,
  });

  @override
  State<_AssignmentVideoCard> createState() => _AssignmentVideoCardState();
}

class _AssignmentVideoCardState extends State<_AssignmentVideoCard> {
  double _scale = 1.0;
  String? _thumbnailUrl;
  bool _isLoading = true;

  final GoogleDriveService _driveService = GoogleDriveService();

  // Static cache to prevent re-fetching thumbnails for the same driveUrl
  static final Map<String, String?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  void _initThumbnail() async {
    final driveUrl = widget.assignment['driveUrl'] as String?;
    if (driveUrl == null || driveUrl.isEmpty) return;
    if (widget.assignment['sourceType'] == 'youtube') {
      setState(() {
        _thumbnailUrl = _youtubeThumbnail(driveUrl);
        _isLoading = false;
      });
      return;
    }

    // 1. Check Cache first
    if (_thumbnailCache.containsKey(driveUrl)) {
      if (mounted) {
        setState(() {
          _thumbnailUrl = _thumbnailCache[driveUrl];
        });
      }
      return;
    }

    String? thumbToUse;

    // 2. Fetch Thumbnail Metadata
    if (driveUrl.contains('/folders/')) {
      final folderId = driveUrl.split('/folders/').last.split('?').first;
      try {
        final exercises = await _driveService.fetchFolderVideos(folderId);
        if (exercises.isNotEmpty) {
          thumbToUse = exercises.first.thumbnailUrl;
        }
      } catch (e) {
        debugPrint('Error fetching thumbnail folder: $e');
      }
    } else {
      // Direct file or API link
      String? fileId;
      if (driveUrl.contains('/file/d/')) {
        fileId = driveUrl.split('/file/d/').last.split('/').first;
      } else if (driveUrl.contains('id=')) {
        fileId = driveUrl.split('id=').last.split('&').first;
      } else if (driveUrl.contains('drive/v3/files/')) {
        fileId = driveUrl.split('drive/v3/files/').last.split('?').first;
      }

      if (fileId != null) {
        try {
          final meta = await _driveService.fetchFileMetadata(fileId);
          thumbToUse = meta['thumbnailUrl'];
        } catch (e) {
          debugPrint('Error fetching file thumbnail for $fileId: $e');
        }
      }
    }

    // 3. Save to Cache and Update State
    _thumbnailCache[driveUrl] = thumbToUse;

    if (mounted) {
      setState(() {
        _thumbnailUrl = thumbToUse;
        _isLoading = false;
      });
    }
  }

  String? _youtubeThumbnail(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    String? id;
    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else {
      id = uri.queryParameters['v'];
    }

    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final title = assignment['workoutTitle'] ?? 'Workout';
    final notes = assignment['notes'] ?? 'Assigned by your coach';
    final driveUrl = assignment['driveUrl'] ?? '';
    final sourceType = assignment['sourceType'] ?? 'google_drive';

    String? folderId;
    if (sourceType == 'google_drive' && driveUrl.contains('/folders/')) {
      folderId = driveUrl.split('/folders/').last.split('?').first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Thumbnail
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: const Color(0xFF1B1B1F),
              image: _thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_thumbnailUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  )
                : (_thumbnailUrl == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Colors.white.withOpacity(0.2),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Video Ready",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        )
                      : null),
          ),

          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: assignment['status'] == 'completed'
                        ? const Color(0xFF2EB87D)
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (assignment['status'] == 'completed')
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      if (assignment['status'] == 'completed')
                        const SizedBox(width: 6),
                      Text(
                        assignment['status'] == 'completed'
                            ? 'COMPLETED'
                            : 'TARGET: ${assignment['scheduledDate'] != null ? (assignment['scheduledDate'] as String).split('T').first : 'TODAY'}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Animated Start Button
                GestureDetector(
                  onTapDown: (_) => setState(() => _scale = 0.95),
                  onTapUp: (_) => setState(() => _scale = 1.0),
                  onTapCancel: () => setState(() => _scale = 1.0),
                  onTap: () async {
                    final Widget screen;
                    if (sourceType == 'youtube') {
                      final workout = Map<String, dynamic>.from(
                        assignment['youtubeWorkout'] as Map? ??
                            <String, dynamic>{
                              '`': title,
                              'Training Video': driveUrl,
                              'NOTES': notes,
                            },
                      );
                      screen = ActiveWorkoutScreen(
                        workout: workout,
                        assignmentId: assignment['id']?.toString(),
                      );
                    } else {
                      screen = ExerciseDetailScreen(
                        folderName: title,
                        folderId: folderId,
                        directVideoUrl: folderId == null ? driveUrl : null,
                        assignmentId: assignment['id']?.toString(),
                        directExercise: assignment['driveWorkout'] is Map
                            ? ExerciseModel.fromMap(
                                Map<String, dynamic>.from(
                                  assignment['driveWorkout'] as Map,
                                ),
                              )
                            : null,
                      );
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => screen),
                    );

                    if (result is WorkoutCompletionAction) {
                      widget.onProgressUpdated?.call();
                      if (result == WorkoutCompletionAction.backHome) {
                        widget.onNavigateHome?.call();
                      } else if (result ==
                          WorkoutCompletionAction.viewProgress) {
                        widget.onNavigateProgress?.call();
                      }
                    }
                  },
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: assignment['status'] == 'completed'
                            ? const Color(0xFF2EB87D).withOpacity(0.9)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            assignment['status'] == 'completed'
                                ? 'REWATCH WORKOUT'
                                : 'START WORKOUT',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: assignment['status'] == 'completed'
                                  ? Colors.white
                                  : Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            assignment['status'] == 'completed'
                                ? Icons.replay_rounded
                                : Icons.play_circle_fill_rounded,
                            color: assignment['status'] == 'completed'
                                ? Colors.white
                                : AppTheme.primary,
                            size: 24,
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
}
