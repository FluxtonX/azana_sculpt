import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_drive_service.dart';
import 'exercise_detail_screen.dart';
import 'workout_testing_screen.dart';

class AllWorkoutsScreen extends StatefulWidget {
  const AllWorkoutsScreen({super.key});

  @override
  State<AllWorkoutsScreen> createState() => _AllWorkoutsScreenState();
}

class _AllWorkoutsScreenState extends State<AllWorkoutsScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "All Workouts",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getClientAssignmentsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No workouts found",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return _WorkoutListItem(
                assignment: assignment,
                driveService: _driveService,
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkoutListItem extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final GoogleDriveService driveService;

  const _WorkoutListItem({
    required this.assignment,
    required this.driveService,
  });

  @override
  State<_WorkoutListItem> createState() => _WorkoutListItemState();
}

class _WorkoutListItemState extends State<_WorkoutListItem> {
  String? _thumbnailUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final driveUrl = widget.assignment['driveUrl'] as String?;
    if (driveUrl == null) return;
    if (widget.assignment['sourceType'] == 'youtube') {
      setState(() {
        _thumbnailUrl = _youtubeThumbnail(driveUrl);
        _loading = false;
      });
      return;
    }

    String? thumb;
    try {
      if (driveUrl.contains('/folders/')) {
        final folderId = driveUrl.split('/folders/').last.split('?').first;
        final videos = await widget.driveService.fetchFolderVideos(folderId);
        if (videos.isNotEmpty) thumb = videos.first.thumbnailUrl;
      } else {
        String? fileId;
        if (driveUrl.contains('/file/d/')) {
          fileId = driveUrl.split('/file/d/').last.split('/').first;
        } else if (driveUrl.contains('id=')) {
          fileId = driveUrl.split('id=').last.split('&').first;
        }
        if (fileId != null) {
          final meta = await widget.driveService.fetchFileMetadata(fileId);
          thumb = meta['thumbnailUrl'];
        }
      }
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
    }

    if (mounted) {
      setState(() {
        _thumbnailUrl = thumb;
        _loading = false;
      });
    }
  }

  String? _youtubeThumbnail(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final id = uri.host.contains('youtu.be')
        ? (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null)
        : uri.queryParameters['v'];
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.assignment['workoutTitle'] ?? 'Workout';
    final date =
        DateTime.tryParse(widget.assignment['assignedAt'] ?? '') ??
        DateTime.now();

    return GestureDetector(
      onTap: () {
        final driveUrl = widget.assignment['driveUrl'] ?? '';
        final sourceType = widget.assignment['sourceType'] ?? 'google_drive';
        String? folderId;
        if (sourceType == 'google_drive' && driveUrl.contains('/folders/')) {
          folderId = driveUrl.split('/folders/').last.split('?').first;
        }

        final Widget screen;
        if (sourceType == 'youtube') {
          final workout = Map<String, dynamic>.from(
            widget.assignment['youtubeWorkout'] as Map? ??
                <String, dynamic>{
                  '`': title,
                  'Training Video': driveUrl,
                  'NOTES': widget.assignment['notes']?.toString() ?? '',
                },
          );
          screen = ActiveWorkoutScreen(
            workout: workout,
            assignmentId: widget.assignment['id']?.toString(),
          );
        } else {
          screen = ExerciseDetailScreen(
            folderName: title,
            folderId: folderId,
            directVideoUrl: folderId == null ? driveUrl : null,
            assignmentId: widget.assignment['id']?.toString(),
            directExercise: widget.assignment['driveWorkout'] is Map
                ? ExerciseModel.fromMap(
                    Map<String, dynamic>.from(
                      widget.assignment['driveWorkout'] as Map,
                    ),
                  )
                : null,
          );
        }

        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primary.withOpacity(0.1),
                image: _thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _loading && _thumbnailUrl == null
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : _thumbnailUrl == null
                  ? const Icon(Icons.play_circle_fill, color: AppTheme.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Assigned on ${date.day}/${date.month}/${date.year}",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textMedium,
            ),
          ],
        ),
      ),
    );
  }
}
