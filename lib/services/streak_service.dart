import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_model.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  static const String _streakKey = 'streak_count';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastActiveDateKey = 'last_active_date';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call on app open and after workout completion.
  /// Returns the updated [StreakModel].
  Future<StreakModel> updateStreak(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateString(now);

    final lastActiveDateStr = prefs.getString(_lastActiveDateKey);
    int currentStreak = prefs.getInt(_streakKey) ?? 0;
    int longestStreak = prefs.getInt(_longestStreakKey) ?? 0;

    if (lastActiveDateStr == null) {
      // First time ever
      currentStreak = 1;
    } else {
      final lastActive = DateTime.parse(lastActiveDateStr);
      final daysDiff = _daysBetween(lastActive, now);

      if (daysDiff == 0) {
        // Already active today — no change
      } else if (daysDiff == 1) {
        // Consecutive day — increment
        currentStreak += 1;
      } else {
        // Gap — reset streak
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    // Persist locally
    await prefs.setString(_lastActiveDateKey, todayStr);
    await prefs.setInt(_streakKey, currentStreak);
    await prefs.setInt(_longestStreakKey, longestStreak);

    // Sync to Firestore (non-blocking)
    _db.collection('users').doc(uid).set({
      'streakCount': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': todayStr,
      'streakUpdatedAt': now.toIso8601String(),
    }, SetOptions(merge: true)).catchError((_) {});

    final isAtRisk = _isStreakAtRisk(lastActiveDateStr, now);

    return StreakModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActiveDate: now,
      isAtRisk: isAtRisk,
    );
  }

  /// Load streak from local cache (fast, offline-first)
  Future<StreakModel> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStreak = prefs.getInt(_streakKey) ?? 0;
    final longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    final lastActiveDateStr = prefs.getString(_lastActiveDateKey);

    DateTime? lastActive;
    if (lastActiveDateStr != null) {
      lastActive = DateTime.tryParse(lastActiveDateStr);
    }

    final isAtRisk = _isStreakAtRisk(lastActiveDateStr, DateTime.now());

    return StreakModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActiveDate: lastActive,
      isAtRisk: isAtRisk,
    );
  }

  /// True if last active date was yesterday and it's now past 8pm,
  /// or if last active was 2+ days ago.
  bool _isStreakAtRisk(String? lastActiveDateStr, DateTime now) {
    if (lastActiveDateStr == null) return false;
    final lastActive = DateTime.tryParse(lastActiveDateStr);
    if (lastActive == null) return false;
    final daysDiff = _daysBetween(lastActive, now);
    if (daysDiff == 1 && now.hour >= 20) return true;
    if (daysDiff >= 2) return true;
    return false;
  }

  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
