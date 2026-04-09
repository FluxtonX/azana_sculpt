import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/program_model.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';
import 'workout_execution_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final DatabaseService _db = DatabaseService();
  Stream<UserModel?>? _userStream;
  Stream<List<ProgramModel>>? _programStream;
  String? _lastCoachId;
  String? _selectedProgramId; // Track selected program

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = _db.userProfileStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, userSnapshot) {
          final profile = userSnapshot.data;
          final coachId = profile?.coachId;

          if (coachId != null && (_programStream == null || coachId != _lastCoachId)) {
            _lastCoachId = coachId;
            _programStream = _db.getAllProgramsStream(coachId: coachId);
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: StreamBuilder<List<ProgramModel>>(
                  stream: _programStream,
                  builder: (context, programSnapshot) {
                    final programs = programSnapshot.data ?? [];
                    
                    // Auto-select first program if none selected
                    if (_selectedProgramId == null && programs.isNotEmpty) {
                      _selectedProgramId = programs.first.id;
                    }

                    // Find the actual selected program object
                    final selectedProgram = programs.firstWhere(
                      (p) => p.id == _selectedProgramId,
                      orElse: () => programs.isNotEmpty ? programs.first : ProgramModel(
                        id: '', coachId: '', title: '', description: '', 
                        duration: '', createdAt: DateTime.now()
                      ),
                    );

                    final hasPrograms = programs.isNotEmpty && selectedProgram.id.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildSectionHeader("Program Library"),
                          const SizedBox(height: 16),
                          _buildProgramLibrary(programs),
                          const SizedBox(height: 32),
                          if (hasPrograms) ...[
                            _buildActiveProgramCard(selectedProgram),
                            const SizedBox(height: 32),
                            _buildSectionHeader("This Week's Workouts"),
                            const SizedBox(height: 16),
                            _buildWorkoutsList(selectedProgram.id),
                          ] else
                            _buildEmptyWorkoutsState(),
                          const SizedBox(height: 32),
                          _buildSectionHeader("Recently Completed"),
                          const SizedBox(height: 16),
                          _buildRecentlyCompletedSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.surface.withOpacity(0.8),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: const Text(
        "Workouts",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildProgramLibrary(List<ProgramModel> programs) {
    if (programs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: programs.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final program = programs[index];
          final isSelected = program.id == _selectedProgramId;

          return _buildProgramLibraryCard(program, isSelected);
        },
      ),
    );
  }

  Widget _buildProgramLibraryCard(ProgramModel program, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProgramId = program.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Thumbnail (Placeholder or Image)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: AppTheme.primary.withOpacity(0.05),
                  child: program.previewImageUrl != null
                      ? Image.network(program.previewImageUrl!, fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primary.withOpacity(0.2),
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program.duration,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProgramCard(ProgramModel? program) {
    if (program == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Text("No active program found. Ask your coach!"),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CURRENT PROGRAM",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDark.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<double>(
            stream: _db.getProgramProgressStream(
              FirebaseAuth.instance.currentUser!.uid,
              program.id,
            ),
            builder: (context, progressSnapshot) {
              final progress = progressSnapshot.data ?? 0.0;
              final percent = (progress * 100).toInt();
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Progress",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                      ),
                      Text(
                        "$percent% Complete",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // We can't easily get the "Day X of Y" without fetching completion records first,
          // but we can calculate it from the progress stream if we assume unique workouts.
          StreamBuilder<double>(
            stream: _db.getProgramProgressStream(
              FirebaseAuth.instance.currentUser!.uid,
              program.id,
            ),
            builder: (context, progressSnapshot) {
              final progress = progressSnapshot.data ?? 0.0;
              return FutureBuilder<int>(
                future: _db.getWorkoutsStream(program.id).first.then((list) => list.length),
                builder: (context, totalSnapshot) {
                  final total = totalSnapshot.data ?? 0;
                  final completed = (progress * total).round();
                  final nextDay = (completed + 1).clamp(1, total == 0 ? 1 : total);
                  
                  return Text(
                    "${program.duration} • Workout $nextDay of $total",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildWorkoutsList(String programId) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<Set<String>>(
      stream: _db.getCompletedWorkoutIdsStream(userId, programId),
      builder: (context, completionSnapshot) {
        final completedIds = completionSnapshot.data ?? {};
        
        debugPrint('DEBUG: Workouts List Build - User: $userId');
        debugPrint('DEBUG: Workouts List Build - Program: $programId');
        debugPrint('DEBUG: Workouts List Build - Completed IDs found: ${completedIds.length}');
        if (completedIds.isNotEmpty) {
           debugPrint('DEBUG: Completed IDs: $completedIds');
        }

        return StreamBuilder<List<WorkoutSession>>(
          stream: _db.getWorkoutsStream(programId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final workouts = snapshot.data ?? [];

            if (workouts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No workouts scheduled yet."),
              );
            }

            return Column(
              children: workouts.asMap().entries.map((entry) {
                final index = entry.key;
                final workout = entry.value;

                // Sequential Unlock Logic:
                // 1. First workout in the sorted list is always unlocked
                // 2. Others are unlocked ONLY if the PREVIOUS workout in the list is completed
                final isCompleted = completedIds.contains(workout.id);
                bool isUnlocked = index == 0 || completedIds.contains(workouts[index - 1].id);
                
                // If the workout itself is completed, it's obviously unlocked too (for re-playing)
                if (isCompleted) isUnlocked = true;

                return _buildWorkoutCard(workout, !isUnlocked, isCompleted);
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkoutCard(WorkoutSession workout, bool isLocked, bool isCompleted) {
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted 
                ? Colors.green.withOpacity(0.3) 
                : (isLocked ? AppTheme.divider.withOpacity(0.2) : AppTheme.divider.withOpacity(0.5)),
            width: isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.1) 
                        : AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (isCompleted ? "Completed" : "Active").toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? Colors.green : AppTheme.accent,
                    ),
                  ),
                ),
                if (isLocked)
                  const Icon(Icons.lock_rounded, size: 18, color: AppTheme.textLight)
                else if (isCompleted)
                  const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              workout.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isLocked ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  workout.totalDuration,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.bolt_rounded, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  "${workout.exercises.length} Exercises",
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLocked ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutExecutionScreen(session: workout),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted 
                      ? Colors.green.withOpacity(0.1) 
                      : (isLocked ? Colors.grey.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1)),
                  foregroundColor: isCompleted ? Colors.green : (isLocked ? Colors.grey : AppTheme.primary),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLocked ? Icons.lock_rounded : (isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded), 
                      size: 20
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLocked ? "Locked" : (isCompleted ? "Replay Session" : "Start Workout"), 
                      style: const TextStyle(fontWeight: FontWeight.w800)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkoutsState() {
    return const Center(child: Text("No programs or workouts found."));
  }

  Widget _buildRecentlyCompletedSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getLatestCompletedWorkoutsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completions = snapshot.data ?? [];

        if (completions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "No workouts completed yet.",
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          );
        }

        return Column(
          children: completions.map((data) {
            final title = data['workoutTitle'] ?? 'Workout';
            final completedAtStr = data['completedAt'] as String?;
            String relativeTime = 'Recently';
            
            if (completedAtStr != null) {
              final completedAt = DateTime.parse(completedAtStr);
              final diff = DateTime.now().difference(completedAt);
              if (diff.inDays == 0) {
                relativeTime = 'Today';
              } else if (diff.inDays == 1) {
                relativeTime = 'Yesterday';
              } else {
                relativeTime = '${diff.inDays} days ago';
              }
            }

            return _buildCompletedTile(title, "Completed $relativeTime");
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompletedTile(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("View", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
