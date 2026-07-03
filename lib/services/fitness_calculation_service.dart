import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

/// Pure calculation helper for fitness formulas.
/// All methods are null-safe — returns null if required inputs are missing.
class FitnessCalculationService {
  static final FitnessCalculationService _instance =
      FitnessCalculationService._internal();
  factory FitnessCalculationService() => _instance;
  FitnessCalculationService._internal();

  // ───────────────────────── Parsing helpers ─────────────────────────

  /// Convert stored height string to cm (handles cm / ft input).
  double? _parseHeightCm(String? height, String? unit) {
    if (height == null || height.isEmpty) return null;
    final value = double.tryParse(height);
    if (value == null || value <= 0) return null;

    if (unit == 'ft') {
      return value * 30.48; // rough ft → cm
    }
    return value; // assume cm
  }

  /// Convert stored weight string to kg (handles kg / lbs input).
  double? _parseWeightKg(String? weight, String? unit) {
    if (weight == null || weight.isEmpty) return null;
    final value = double.tryParse(weight);
    if (value == null || value <= 0) return null;

    if (unit == 'lbs') {
      return value * 0.453592;
    }
    return value; // assume kg
  }

  /// Map the stored activityLevel (string "1"–"5" or descriptive) to a multiplier.
  double _activityFactor(String? activityLevel) {
    if (activityLevel == null) return 1.2;

    // Onboarding stores 1–5 scale as a string
    final numLevel = int.tryParse(activityLevel);
    if (numLevel != null) {
      if (numLevel <= 2) return 1.2; // Beginner / Sedentary
      if (numLevel <= 3) return 1.55; // Moderate
      return 1.725; // Active
    }

    // Descriptive fallback
    final lower = activityLevel.toLowerCase();
    if (lower.contains('active')) return 1.725;
    if (lower.contains('moderate')) return 1.55;
    return 1.2; // beginner / sedentary / default
  }

  // ─────────────────────── Formula implementations ───────────────────────

  /// BMI = weightKg / (heightM * heightM)
  double? calculateBMI({required double? weightKg, required double? heightCm}) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));
  }

  /// BMR using Mifflin-St Jeor equation.
  /// Male:   10 * weightKg + 6.25 * heightCm - 5 * age + 5
  /// Female: 10 * weightKg + 6.25 * heightCm - 5 * age - 161
  double? calculateBMR({
    required double? weightKg,
    required double? heightCm,
    required int? age,
    required String? gender,
  }) {
    if (weightKg == null || heightCm == null || age == null) return null;
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return null;

    final isMale =
        gender == null ||
        gender.toLowerCase().contains('male') &&
            !gender.toLowerCase().contains('female');

    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return double.parse((isMale ? base + 5 : base - 161).toStringAsFixed(0));
  }

  /// Daily Calories = BMR * activityFactor
  double? calculateDailyCalories({
    required double? bmr,
    required String? activityLevel,
  }) {
    if (bmr == null) return null;
    return double.parse(
      (bmr * _activityFactor(activityLevel)).toStringAsFixed(0),
    );
  }

  /// Goal-based calorie target.
  ///   Weight Loss  → dailyCalories - 500
  ///   Muscle Gain  → dailyCalories + 300
  ///   Maintenance  → dailyCalories
  double? calculateTargetCalories({
    required double? dailyCalories,
    required String? fitnessGoal,
  }) {
    if (dailyCalories == null) return null;
    final lower = (fitnessGoal ?? '').toLowerCase();

    if (lower.contains('lose') ||
        lower.contains('loss') ||
        lower.contains('cut')) {
      return dailyCalories - 500;
    }
    if (lower.contains('gain') ||
        lower.contains('muscle') ||
        lower.contains('bulk')) {
      return dailyCalories + 300;
    }
    return dailyCalories; // Maintenance / Combo / unknown
  }

  /// Protein goal = weightKg * 2 (grams/day)
  double? calculateProteinGoal({required double? weightKg}) {
    if (weightKg == null || weightKg <= 0) return null;
    return double.parse((weightKg * 2).toStringAsFixed(0));
  }

  /// Water goal = weightKg * 0.033 (litres/day)
  double? calculateWaterGoal({required double? weightKg}) {
    if (weightKg == null || weightKg <= 0) return null;
    return double.parse((weightKg * 0.033).toStringAsFixed(1));
  }

  // ──────────────────── High-level convenience methods ────────────────────

  /// Calculates all fitness metrics from a UserModel and returns a map of
  /// the computed fields — ready to merge into Firestore.
  Map<String, dynamic> calculateAll(UserModel user) {
    final weightKg = _parseWeightKg(user.weight, user.weightUnit);
    final heightCm = _parseHeightCm(user.height, user.heightUnit);

    final bmi = calculateBMI(weightKg: weightKg, heightCm: heightCm);
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: user.age,
      gender: user.gender,
    );
    final dailyCalories = calculateDailyCalories(
      bmr: bmr,
      activityLevel: user.activityLevel,
    );
    final targetCalories = calculateTargetCalories(
      dailyCalories: dailyCalories,
      fitnessGoal: user.fitnessGoal,
    );
    final proteinGoal = calculateProteinGoal(weightKg: weightKg);
    final waterGoal = calculateWaterGoal(weightKg: weightKg);

    return {
      'bmi': bmi,
      'bmr': bmr,
      'dailyCalories': dailyCalories,
      'targetCalories': targetCalories,
      'proteinGoal': proteinGoal,
      'waterGoal': waterGoal,
    };
  }

  /// Calculate all metrics and persist them to Firestore for the given user.
  /// This is the single call-site you hook after onboarding / profile update.
  Future<void> calculateAndSave(UserModel user) async {
    final metrics = calculateAll(user);

    // Only write fields that have actual values (skip nulls)
    final nonNullMetrics = Map<String, dynamic>.fromEntries(
      metrics.entries.where((e) => e.value != null),
    );

    if (nonNullMetrics.isEmpty) {
      debugPrint('[FitnessCalc] No metrics could be computed — skipping save.');
      return;
    }

    try {
      await DatabaseService().updateUserProfile(user.uid, nonNullMetrics);
      debugPrint(
        '[FitnessCalc] Saved metrics for ${user.uid}: $nonNullMetrics',
      );
    } catch (e) {
      debugPrint('[FitnessCalc] Error saving metrics: $e');
    }
  }

  // ──────────────── Workout Progress ────────────────

  /// progressPercent = completedWorkouts / totalAssignedWorkouts * 100
  /// Returns 0 if no assignments exist.
  double calculateWorkoutProgress({
    required int completedWorkouts,
    required int totalAssignedWorkouts,
  }) {
    if (totalAssignedWorkouts <= 0) return 0.0;
    return double.parse(
      ((completedWorkouts / totalAssignedWorkouts) * 100)
          .clamp(0.0, 100.0)
          .toStringAsFixed(1),
    );
  }

  double _normalizedLevel(double? value) {
    if (value == null || value <= 0) return 0.0;
    final normalized = value > 10 ? value / 100 : value / 10;
    return normalized.clamp(0.0, 1.0);
  }

  double _profileCompletenessScore(
    UserModel user,
    Map<String, dynamic> metrics,
  ) {
    final requiredValues = [
      user.height,
      user.weight,
      user.age,
      user.gender,
      user.activityLevel,
      user.fitnessGoal,
    ];

    final completed = requiredValues.where((value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      return true;
    }).length;

    final base = completed / requiredValues.length;
    final bmi = metrics['bmi'] as double?;
    final bmiQuality = bmi == null
        ? 0.0
        : bmi >= 18.5 && bmi <= 30
        ? 1.0
        : 0.65;

    return ((base * 0.8) + (bmiQuality * 0.2)).clamp(0.0, 1.0);
  }

  /// A real client-facing fitness score out of 100.
  ///
  /// Formula:
  /// - 45% assigned workout progress, or recorded workout activity if no plan exists yet
  /// - 20% completed profile/body metrics
  /// - 20% current streak consistency, capped at 14 days
  /// - 15% commitment and motivation readiness
  double calculateFitnessScore({
    required UserModel user,
    required Map<String, dynamic> metrics,
    required int assignedCompletedWorkouts,
    required int totalAssignedWorkouts,
    required int totalRecordedWorkouts,
  }) {
    final progressPercent = calculateWorkoutProgress(
      completedWorkouts: assignedCompletedWorkouts,
      totalAssignedWorkouts: totalAssignedWorkouts,
    );

    final workoutScore = totalAssignedWorkouts > 0
        ? progressPercent / 100
        : (totalRecordedWorkouts / 12).clamp(0.0, 1.0);
    final profileScore = _profileCompletenessScore(user, metrics);
    final streakScore = ((user.streakCount ?? 0) / 14).clamp(0.0, 1.0);
    final readinessScore =
        (_normalizedLevel(user.commitmentLevel) +
            _normalizedLevel(user.motivationLevel)) /
        2;

    final score =
        (workoutScore * 45) +
        (profileScore * 20) +
        (streakScore * 20) +
        (readinessScore * 15);

    return double.parse(score.clamp(0.0, 100.0).toStringAsFixed(1));
  }

  Future<int> _getCompletedWorkoutCount(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('completed_workouts')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getWeeklyCompletedWorkoutCount(String userId) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('completed_workouts')
        .where('userId', isEqualTo: userId)
        .get();

    var count = 0;
    for (final doc in snapshot.docs) {
      final completedAt = DateTime.tryParse(
        doc.data()['completedAt']?.toString() ?? '',
      );
      if (completedAt == null) continue;
      final completedDay = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      if (!completedDay.isBefore(startOfWeek)) count++;
    }
    return count;
  }

  /// Fetches assignment data from Firestore, computes progressPercent,
  /// and saves it to the user document.
  Future<Map<String, dynamic>?> calculateAndSaveFitnessScore(
    String userId,
  ) async {
    try {
      final user = await DatabaseService().getUserProfile(userId, fresh: true);
      if (user == null) return null;

      final assignments = await DatabaseService()
          .getClientAssignmentsStream(userId)
          .first;

      final totalAssigned = assignments.length;
      final completedCount = assignments
          .where((a) => a['status'] == 'completed')
          .length;
      final totalRecordedWorkouts = await _getCompletedWorkoutCount(userId);
      final weeklyCompletedWorkouts = await _getWeeklyCompletedWorkoutCount(
        userId,
      );

      final progressPercent = calculateWorkoutProgress(
        completedWorkouts: completedCount,
        totalAssignedWorkouts: totalAssigned,
      );
      final metrics = calculateAll(user);
      final fitnessScore = calculateFitnessScore(
        user: user,
        metrics: metrics,
        assignedCompletedWorkouts: completedCount,
        totalAssignedWorkouts: totalAssigned,
        totalRecordedWorkouts: totalRecordedWorkouts,
      );

      final now = DateTime.now().toIso8601String();
      final update = <String, dynamic>{
        ...Map<String, dynamic>.fromEntries(
          metrics.entries.where((entry) => entry.value != null),
        ),
        'fitnessScore': fitnessScore,
        'fitnessScoreFormulaVersion': 1,
        'progressPercent': progressPercent,
        'totalAssignedWorkouts': totalAssigned,
        'assignedCompletedWorkouts': completedCount,
        'completedWorkouts': totalRecordedWorkouts,
        'totalWorkouts': totalRecordedWorkouts,
        'weeklyCompletedWorkouts': weeklyCompletedWorkouts,
        'workoutProgressUpdatedAt': now,
        'fitnessScoreUpdatedAt': now,
      };

      await DatabaseService().updateUserProfile(userId, update);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc('summary')
          .set(update, SetOptions(merge: true));

      debugPrint(
        '[FitnessCalc] Fitness score for $userId: $fitnessScore '
        '($completedCount/$totalAssigned assigned, '
        '$totalRecordedWorkouts completed records)',
      );
      return update;
    } catch (e) {
      debugPrint('[FitnessCalc] Error saving fitness score: $e');
      return null;
    }
  }

  /// Backwards-compatible call used after workouts/assignments change.
  Future<void> calculateAndSaveProgress(String userId) async {
    await calculateAndSaveFitnessScore(userId);
  }
}
