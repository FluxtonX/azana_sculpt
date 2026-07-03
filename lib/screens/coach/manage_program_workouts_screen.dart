import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  State<ManageProgramWorkoutsScreen> createState() =>
      _ManageProgramWorkoutsScreenState();
}

class _ManageProgramWorkoutsScreenState
    extends State<ManageProgramWorkoutsScreen> {
  final _dbService = DatabaseService();
  bool _isAdding = false;

  Future<void> _showAddWorkoutSheet(
    List<WorkoutSession> currentWorkouts,
  ) async {
    final titleController = TextEditingController();
    final durationController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Workout Session',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a structured session to your program.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernTextField(
                label: 'Session Title',
                controller: titleController,
                hint: 'e.g. Day 1: Upper Body Flow',
                icon: Icons.fitness_center_rounded,
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                label: 'Estimated Duration',
                controller: durationController,
                hint: 'e.g. 45 min',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'CREATE SESSION',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
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
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.redAccent,
              ),
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
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppTheme.primary, size: 20)
                : null,
            hintStyle: GoogleFonts.outfit(
              color: AppTheme.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Session Designer',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              widget.program.title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildProgressHeader(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isAdding
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<WorkoutSession>>(
                    stream: _dbService.getWorkoutsStream(widget.program.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final workouts = snapshot.data ?? [];

                      if (workouts.isEmpty) {
                        return _buildEmptyState(workouts);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          return _buildWorkoutCard(workout, index);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _dbService.getWorkoutsStream(widget.program.id).first.then((list) {
            _showAddWorkoutSheet(list);
          });
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'ADD SESSION',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      children: [
        _buildStepIndicator('1', 'Basic Info', true, true),
        Expanded(
          child: Container(
            height: 2,
            color: AppTheme.primary,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepIndicator('2', 'Workouts', true, false),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        _buildStepIndicator('3', 'Exercises', false, false),
      ],
    );
  }

  Widget _buildStepIndicator(
    String step,
    String label,
    bool isActive,
    bool isDone,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? (isDone ? AppTheme.primary : Colors.white)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primary : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppTheme.primary : Colors.grey[400],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.primary : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(WorkoutSession workout, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: AppTheme.primary.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          workout.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                '${workout.exercises.length} Exercises',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                workout.totalDuration,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.textLight,
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
    );
  }

  Widget _buildEmptyState(List<WorkoutSession> workouts) {
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
              child: Icon(
                Icons.fitness_center_rounded,
                size: 64,
                color: AppTheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No sessions yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first workout session to this program.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddWorkoutSheet(workouts),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add First Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
