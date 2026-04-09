import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_theme.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';

class EditWorkoutExercisesScreen extends StatefulWidget {
  final String programId;
  final WorkoutSession workout;

  const EditWorkoutExercisesScreen({
    super.key,
    required this.programId,
    required this.workout,
  });

  @override
  State<EditWorkoutExercisesScreen> createState() => _EditWorkoutExercisesScreenState();
}

class _EditWorkoutExercisesScreenState extends State<EditWorkoutExercisesScreen> {
  late List<ExerciseModel> _exercises;
  final _dbService = DatabaseService();
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.workout.exercises);
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await _dbService.updateWorkoutExercises(
        widget.programId,
        widget.workout.id,
        _exercises,
      );
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All changes saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: AppTheme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 13),
            filled: true,
            fillColor: AppTheme.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _addExercise() {
    final nameController = TextEditingController();
    final instructionController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    final restController = TextEditingController(text: '60');

    showModalBottomSheet(
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
                    'New Exercise',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField('Exercise Name', nameController, hint: 'e.g. Bulgarian Split Squat'),
              const SizedBox(height: 20),
              _buildTextField('Instructions', instructionController, maxLines: 3, hint: 'e.g. Keep your chest up and core engaged...'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildTextField('Sets', setsController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Reps/Time', repsController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Rest (s)', restController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _exercises.add(ExerciseModel(
                        id: const Uuid().v4(),
                        name: nameController.text.trim(),
                        instruction: instructionController.text.trim(),
                        sets: int.tryParse(setsController.text) ?? 3,
                        reps: repsController.text.trim(),
                        restSeconds: int.tryParse(restController.text) ?? 60,
                      ));
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'ADD TO SESSION',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Column(
            children: [
              const Text(
                'STEP 3: EXERCISES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                widget.workout.title,
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
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (!_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary),
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _exercises.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.format_list_bulleted_rounded,
                                  size: 64, color: AppTheme.accent.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No exercises yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Define the routine for this workout session.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: _addExercise,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add First Exercise'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: _exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _exercises.removeAt(oldIndex);
                          _exercises.insert(newIndex, item);
                          _hasUnsavedChanges = true;
                        });
                      },
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Container(
                          key: ValueKey(exercise.id),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: AppTheme.divider.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.transparent,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(20),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${exercise.sets} sets • ${exercise.reps} reps • ${exercise.restSeconds}s rest',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMedium,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(Icons.drag_indicator_rounded, color: AppTheme.textLight),
                                onLongPress: () {
                                  setState(() {
                                    _exercises.removeAt(index);
                                    _hasUnsavedChanges = true;
                                  });
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_hasUnsavedChanges)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('SAVE ALL CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _hasUnsavedChanges ? null : FloatingActionButton(
          onPressed: _addExercise,
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
