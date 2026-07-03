import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fitness_calculation_service.dart';

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
  static const String _completionIdsKey = 'completed_workout_ids';
  static const int weeklyGoal = 5;

  Future<WorkoutProgressSnapshot> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completionHistory = prefs.getStringList(_completionHistoryKey) ?? [];

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await FitnessCalculationService().calculateAndSaveFitnessScore(uid);
    }

    final remoteProgress = await _loadRemoteProgress();

    if (remoteProgress != null) {
      final localCompletedIds = prefs.getStringList(_completionIdsKey) ?? [];
      final remoteCompletedIds = await _loadRemoteCompletionIds();
      final syncedCompletedIds = {
        ...localCompletedIds,
        ...remoteCompletedIds,
      }.toList();

      await prefs.setDouble(_fitnessScoreKey, remoteProgress.fitnessScore);
      await prefs.setInt(
        _completedWorkoutsKey,
        remoteProgress.completedWorkouts,
      );
      await prefs.setStringList(_completionIdsKey, syncedCompletedIds);

      return WorkoutProgressSnapshot(
        fitnessScore: remoteProgress.fitnessScore,
        completedWorkouts: remoteProgress.completedWorkouts,
        weeklyCompletedWorkouts: remoteProgress.weeklyCompletedWorkouts,
        completionHistory: completionHistory,
      );
    }

    return WorkoutProgressSnapshot(
      fitnessScore: prefs.getDouble(_fitnessScoreKey) ?? 0.0,
      completedWorkouts: prefs.getInt(_completedWorkoutsKey) ?? 0,
      weeklyCompletedWorkouts: _countThisWeek(completionHistory),
      completionHistory: completionHistory,
    );
  }

  Future<WorkoutProgressSnapshot> recordWorkoutCompletion({
    int scoreIncrement = 10,
    String? completionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final remoteCompletedIds = await _loadRemoteCompletionIds();
    final completedIds = {
      ...prefs.getStringList(_completionIdsKey) ?? const <String>[],
      ...remoteCompletedIds,
    }.toList();

    if (completionId != null &&
        completionId.isNotEmpty &&
        completedIds.contains(completionId)) {
      return loadProgress();
    }

    final updatedHistory = List<String>.from(
      prefs.getStringList(_completionHistoryKey) ?? const <String>[],
    )..add(now.toIso8601String());
    final updatedCompletedIds = List<String>.from(completedIds);

    if (completionId != null && completionId.isNotEmpty) {
      updatedCompletedIds.add(completionId);
    }

    await prefs.setStringList(_completionHistoryKey, updatedHistory);
    await prefs.setStringList(_completionIdsKey, updatedCompletedIds);
    await _saveRemoteCompletion(
      completionIds: updatedCompletedIds,
      completedAt: now,
    );
    await _saveCompletedWorkoutRecord(
      completionId: completionId,
      completedAt: now,
    );

    return loadProgress();
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

  Future<WorkoutProgressSnapshot?> _loadRemoteProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return null;

      final score = (data['fitnessScore'] as num?)?.toDouble();
      final completed =
          (data['completedWorkouts'] as num?)?.toInt() ??
          (data['totalWorkouts'] as num?)?.toInt() ??
          (data['assignedCompletedWorkouts'] as num?)?.toInt();
      final weekly = (data['weeklyCompletedWorkouts'] as num?)?.toInt() ?? 0;

      if (score == null && completed == null) return null;

      return WorkoutProgressSnapshot(
        fitnessScore: score ?? 0.0,
        completedWorkouts: completed ?? 0,
        weeklyCompletedWorkouts: weekly,
        completionHistory: const [],
      );
    } catch (e) {
      debugPrint('Error loading workout progress from Firebase: $e');
      return null;
    }
  }

  Future<void> _saveRemoteCompletion({
    required List<String> completionIds,
    required DateTime completedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'completedWorkoutIds': completionIds,
        'lastWorkoutCompletedAt': completedAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving workout progress to Firebase: $e');
    }
  }

  Future<void> _saveCompletedWorkoutRecord({
    required String? completionId,
    required DateTime completedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final safeCompletionId = completionId?.trim();
    final docId = safeCompletionId != null && safeCompletionId.isNotEmpty
        ? '${uid}_$safeCompletionId'
        : '${uid}_${completedAt.millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance
          .collection('completed_workouts')
          .doc(docId)
          .set({
            'userId': uid,
            'programId': 'client_workout',
            'workoutId': safeCompletionId ?? docId,
            'workoutTitle': 'Workout',
            'duration': 0,
            'exercisesCount': 0,
            'calories': 0,
            'source': 'client_completion',
            'completedAt': completedAt.toIso8601String(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving completed workout record: $e');
    }
  }

  Future<List<String>> _loadRemoteCompletionIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const [];

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return const [];
      return List<String>.from(data['completedWorkoutIds'] ?? const []);
    } catch (e) {
      debugPrint('Error loading remote workout completion ids: $e');
      return const [];
    }
  }
}
