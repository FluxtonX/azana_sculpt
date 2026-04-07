class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final bool isAtRisk;

  const StreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.isAtRisk = false,
  });

  /// Returns the emoji/icon tier for the streak milestone
  String get streakEmoji {
    if (currentStreak >= 30) return '👑';
    if (currentStreak >= 14) return '⚡';
    if (currentStreak >= 7) return '🔥';
    if (currentStreak >= 3) return '✨';
    return '💪';
  }

  /// Label shown next to the streak count
  String get streakLabel {
    if (currentStreak == 0) return 'Start your streak!';
    if (currentStreak == 1) return '1 Day Streak';
    return '$currentStreak Day Streak';
  }

  /// Subtitle copy for the streak banner
  String get streakSubtitle {
    if (isAtRisk) return "Don't break your streak — train today! 🔥";
    if (currentStreak >= 30) return 'You are an absolute icon. Keep going! 👑';
    if (currentStreak >= 14) return 'Two weeks strong. Nothing can stop you. ⚡';
    if (currentStreak >= 7) return 'One week of consistency. You are on fire!';
    if (currentStreak >= 3) return 'Three days in. The habit is forming!';
    return 'Show up today. Your future self will thank you.';
  }

  StreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    bool? isAtRisk,
  }) {
    return StreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isAtRisk: isAtRisk ?? this.isAtRisk,
    );
  }
}
