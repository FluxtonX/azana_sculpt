class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int requiredStreak;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredStreak,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  BadgeModel copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return BadgeModel(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      requiredStreak: requiredStreak,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };
}

/// All available badges in the app
class AppBadges {
  static const List<BadgeModel> all = [
    BadgeModel(
      id: 'first_workout',
      title: 'First Step',
      description: 'Completed your very first workout',
      emoji: '🌸',
      requiredStreak: 1,
    ),
    BadgeModel(
      id: 'streak_3',
      title: '3-Day Spark',
      description: 'Maintained a 3-day streak',
      emoji: '✨',
      requiredStreak: 3,
    ),
    BadgeModel(
      id: 'streak_7',
      title: '7-Day Consistency',
      description: 'One full week of daily movement',
      emoji: '🔥',
      requiredStreak: 7,
    ),
    BadgeModel(
      id: 'streak_14',
      title: '14-Day Discipline',
      description: 'Two weeks of unstoppable discipline',
      emoji: '⚡',
      requiredStreak: 14,
    ),
    BadgeModel(
      id: 'streak_30',
      title: '30-Day Transformation',
      description: 'A full month of commitment',
      emoji: '💎',
      requiredStreak: 30,
    ),
    BadgeModel(
      id: 'streak_60',
      title: '60-Day Elite',
      description: 'Two months of elite-level dedication',
      emoji: '🏆',
      requiredStreak: 60,
    ),
    BadgeModel(
      id: 'streak_90',
      title: '90-Day Icon',
      description: 'You are the definition of transformation',
      emoji: '👑',
      requiredStreak: 90,
    ),
  ];

  static BadgeModel? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
