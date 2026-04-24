import 'package:shared_preferences/shared_preferences.dart';

class WorkoutProgressSnapshot {
  final double fitnessScore;
  final int completedWorkouts;
  final int weeklyCompletedWorkouts;
  final List<String> completionHistory;

  const WorkoutProgressSnapshot({
    required this.fitnessScore,
    required this.completedWorkouts,
    required this.weeklyCompletedWorkouts,
    required this.completionHistory,
  });
}

class WorkoutProgressService {
  static const String _fitnessScoreKey = 'fitness_score';
  static const String _completedWorkoutsKey = 'completed_workouts_count';
  static const String _completionHistoryKey = 'completed_workout_dates';
  static const int weeklyGoal = 5;

  Future<WorkoutProgressSnapshot> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completionHistory = prefs.getStringList(_completionHistoryKey) ?? [];

    return WorkoutProgressSnapshot(
      fitnessScore: prefs.getDouble(_fitnessScoreKey) ?? 0.0,
      completedWorkouts: prefs.getInt(_completedWorkoutsKey) ?? 0,
      weeklyCompletedWorkouts: _countThisWeek(completionHistory),
      completionHistory: completionHistory,
    );
  }

  Future<WorkoutProgressSnapshot> recordWorkoutCompletion({
    int scoreIncrement = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final updatedHistory = List<String>.from(
      prefs.getStringList(_completionHistoryKey) ?? const <String>[],
    )..add(now.toIso8601String());

    final updatedWorkoutCount = (prefs.getInt(_completedWorkoutsKey) ?? 0) + 1;
    final updatedScore = ((prefs.getDouble(_fitnessScoreKey) ?? 0.0) +
            scoreIncrement)
        .clamp(0.0, 100.0);

    await prefs.setStringList(_completionHistoryKey, updatedHistory);
    await prefs.setInt(_completedWorkoutsKey, updatedWorkoutCount);
    await prefs.setDouble(_fitnessScoreKey, updatedScore);

    return WorkoutProgressSnapshot(
      fitnessScore: updatedScore,
      completedWorkouts: updatedWorkoutCount,
      weeklyCompletedWorkouts: _countThisWeek(updatedHistory, now: now),
      completionHistory: updatedHistory,
    );
  }

  int _countThisWeek(List<String> completionHistory, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfWeek = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));

    var count = 0;
    for (final rawDate in completionHistory) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) continue;
      final completedOn = DateTime(parsed.year, parsed.month, parsed.day);
      if (!completedOn.isBefore(startOfWeek)) {
        count++;
      }
    }
    return count;
  }
}
