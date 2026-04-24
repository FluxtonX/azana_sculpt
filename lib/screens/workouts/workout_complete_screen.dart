import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';

enum WorkoutCompletionAction { backHome, viewProgress }

class WorkoutCompletionSummary {
  final String title;
  final String subtitle;
  final String? badgeAssetPath;
  final int durationMinutes;
  final int exerciseCount;
  final int weeklyCompleted;
  final int weeklyGoal;
  final int streakDays;
  final int scoreAdded;
  final int totalScore;

  const WorkoutCompletionSummary({
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.exerciseCount,
    required this.weeklyCompleted,
    required this.weeklyGoal,
    required this.streakDays,
    required this.scoreAdded,
    required this.totalScore,
    this.badgeAssetPath,
  });
}

class WorkoutCompleteScreen extends StatelessWidget {
  final WorkoutCompletionSummary summary;

  const WorkoutCompleteScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3D3CC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2D4CD), Color(0xFFECCBC3), Color(0xFFE9C5BD)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: Column(
              children: [
                _buildBadge(),
                const SizedBox(height: 18),
                Text(
                  summary.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  context,
                  label: 'Back to Home',
                  onPressed: () {
                    Navigator.of(context).pop(WorkoutCompletionAction.backHome);
                  },
                ),
                const SizedBox(height: 12),
                _buildSecondaryButton(
                  context,
                  label: 'View Progress',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(WorkoutCompletionAction.viewProgress);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA7D73).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: summary.badgeAssetPath != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(summary.badgeAssetPath!, fit: BoxFit.contain),
            )
          : const Icon(
              Icons.emoji_events_rounded,
              size: 34,
              color: AppTheme.primary,
            ),
    );
  }

  Widget _buildSummaryCard() {
    final weeklyProgress = summary.weeklyGoal == 0
        ? 0.0
        : (summary.weeklyCompleted / summary.weeklyGoal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Workout Summary',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${summary.durationMinutes} min',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercises',
                  value: '${summary.exerciseCount}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.stars_rounded,
                  label: 'Score',
                  value: '+${summary.scoreAdded}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F3F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: weeklyProgress,
                      backgroundColor: const Color(0xFFEAD9D4),
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${summary.weeklyCompleted} of ${summary.weeklyGoal}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFooterPill(
                  label: 'Current Streak',
                  value: summary.streakDays <= 1
                      ? 'First Day'
                      : '${summary.streakDays}-Days',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFooterPill(
                  label: 'Fitness Score',
                  value: '${summary.totalScore}/100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F3F1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterPill({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0D5CF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
