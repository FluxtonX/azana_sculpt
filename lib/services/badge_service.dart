import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  static const String _badgesKey = 'unlocked_badges';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Checks current streak against badge thresholds.
  /// Returns any *newly* unlocked [BadgeModel]s (for showing unlock animation).
  Future<List<BadgeModel>> checkAndUnlockBadges(
      String uid, int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyUnlocked = prefs.getStringList(_badgesKey) ?? [];

    final newlyUnlocked = <BadgeModel>[];

    for (final badge in AppBadges.all) {
      if (currentStreak >= badge.requiredStreak &&
          !alreadyUnlocked.contains(badge.id)) {
        newlyUnlocked.add(badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
        alreadyUnlocked.add(badge.id);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      // Persist locally
      await prefs.setStringList(_badgesKey, alreadyUnlocked);

      // Sync to Firestore
      _db.collection('users').doc(uid).set({
        'unlockedBadges': alreadyUnlocked,
      }, SetOptions(merge: true)).catchError((_) {});
    }

    return newlyUnlocked;
  }

  /// Load all badges with their unlock status
  Future<List<BadgeModel>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList(_badgesKey) ?? [];

    return AppBadges.all.map((badge) {
      return badge.copyWith(isUnlocked: unlockedIds.contains(badge.id));
    }).toList();
  }

  /// Returns only unlocked badges
  Future<List<BadgeModel>> loadUnlockedBadges() async {
    final all = await loadBadges();
    return all.where((b) => b.isUnlocked).toList();
  }
}
