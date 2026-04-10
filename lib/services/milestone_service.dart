import '../models/achievement_models.dart';

class MilestoneService {
  /// Resolves the current milestone based on the provided streak value.
  AchievementMilestone? getMilestoneFromStreak(int streak) {
    return AchievementMilestone.fromStreak(streak);
  }
}
