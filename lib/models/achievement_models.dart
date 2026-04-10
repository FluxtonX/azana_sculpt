enum AchievementMilestone {
  first(1, 'assets/excompleteicon/badge_streak_1.png', 'First Workout Complete'),
  streak3(3, 'assets/excompleteicon/badge_streak_3.png', '3-Day Streak Complete'),
  streak7(7, 'assets/excompleteicon/badge_streak_7.png', '7-Day Streak Complete'),
  streak14(14, 'assets/excompleteicon/badge_streak_14.png', '14-Day Streak Complete'),
  streak30(30, 'assets/excompleteicon/badge_streak_30.png', '30-Day Streak Complete'),
  streak60(60, 'assets/excompleteicon/badge_streak_60.png', '60-Day Streak Complete'),
  streak90(90, 'assets/excompleteicon/badge_streak_90.png', '90-Day Streak Complete');

  final int requiredDays;
  final String assetPath;
  final String title;

  const AchievementMilestone(this.requiredDays, this.assetPath, this.title);

  /// Returns the highest milestone reached based on current streak.
  /// Defaults to 'first' if streak is >= 1 but < 3.
  static AchievementMilestone? fromStreak(int streak) {
    if (streak <= 0) return null;
    
    // Check milestones from highest to lowest
    final milestones = AchievementMilestone.values.reversed.toList();
    for (final milestone in milestones) {
      if (streak >= milestone.requiredDays) {
        return milestone;
      }
    }
    
    return AchievementMilestone.first;
  }
}
