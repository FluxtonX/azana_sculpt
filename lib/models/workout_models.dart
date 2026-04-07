class ExerciseModel {
  final String name;
  final String instruction;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? videoUrl;

  ExerciseModel({
    required this.name,
    required this.instruction,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.videoUrl,
  });
}

class WorkoutSession {
  final String title;
  final List<ExerciseModel> exercises;
  final String totalDuration;
  final int caloriesBurned;

  WorkoutSession({
    required this.title,
    required this.exercises,
    required this.totalDuration,
    required this.caloriesBurned,
  });
}
