import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_theme.dart';
import '../../models/program_model.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';
import 'edit_workout_exercises_screen.dart';

class ManageProgramWorkoutsScreen extends StatefulWidget {
  final ProgramModel program;

  const ManageProgramWorkoutsScreen({super.key, required this.program});

  @override
  State<ManageProgramWorkoutsScreen> createState() => _ManageProgramWorkoutsScreenState();
}

class _ManageProgramWorkoutsScreenState extends State<ManageProgramWorkoutsScreen> {
  final _dbService = DatabaseService();
  bool _isAdding = false;
  
  Future<void> _showAddWorkoutSheet(List<WorkoutSession> currentWorkouts) async {
    final titleController = TextEditingController();
    final durationController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Workout Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Define a new session for this program.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                label: 'Workout Title',
                controller: titleController,
                hint: 'e.g. Day 1: Upper Body Flow',
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                label: 'Estimated Duration',
                controller: durationController,
                hint: 'e.g. 45 min',
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  if (titleController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'ADD SESSION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ).then((result) async {
      if (result == true && titleController.text.isNotEmpty) {
        if (mounted) setState(() => _isAdding = true);
        try {
          final newWorkout = WorkoutSession(
            id: const Uuid().v4(),
            programId: widget.program.id,
            title: titleController.text.trim(),
            exercises: [],
            totalDuration: durationController.text.trim(),
            caloriesBurned: 0,
            orderIndex: currentWorkouts.length,
          );
          await _dbService.addWorkoutToProgram(widget.program.id, newWorkout);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isAdding = false);
        }
      }
    });
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'STEP 2: ADD WORKOUTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              widget.program.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isAdding
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<WorkoutSession>>(
              stream: _dbService.getWorkoutsStream(widget.program.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workouts = snapshot.data ?? [];

                if (workouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.fitness_center_rounded, size: 64, color: AppTheme.primary.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No sessions yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the button below to add your first workout session to this program.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => _showAddWorkoutSheet(workouts),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      title: Text(
                        workout.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.textDark,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 14, color: AppTheme.primary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${workout.exercises.length} Exercises',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text(
                              workout.totalDuration,
                              style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditWorkoutExercisesScreen(
                              programId: widget.program.id,
                              workout: workout,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We need current workouts to set the next orderIndex
          // Since we are in a stream, we can't easily get them here
          // But we can trigger a one-time fetch or use a variable
          _dbService.getWorkoutsStream(widget.program.id).first.then((list) {
            _showAddWorkoutSheet(list);
          });
        },
        backgroundColor: AppTheme.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
