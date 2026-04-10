import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/streak_service.dart';
import '../../services/milestone_service.dart';
import '../../models/streak_model.dart';
import '../../widgets/streak_badge.dart';
import '../profile/badges_screen.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  final String duration;
  final int exercisesCount;
  final int calories;
  final String programId;

  const WorkoutCompleteScreen({
    super.key,
    required this.programId,
    this.duration = '45 min',
    this.exercisesCount = 8,
    this.calories = 0,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8A49C), Color(0xFFE8B8A8)],
            stops: [0.0, 0.4],
          ),
        ),
        child: FutureBuilder<StreakModel>(
          future: StreakService().loadStreak(),
          builder: (context, streakSnapshot) {
            final streakCount = streakSnapshot.data?.currentStreak ?? 1;

            // Resolve milestone using professional MilestoneService
            final milestone = MilestoneService().getMilestoneFromStreak(
              streakCount,
            );

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Reusable StreakBadge Widget (Handles Image, Title, and Styling)
                  if (milestone != null)
                    StreakBadge(milestone: milestone)
                  else
                    const Column(
                      children: [
                        SizedBox(height: 140),
                        SizedBox(height: 24),
                        Text(
                          'Workout\nComplete!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),
                  const Text(
                    'Amazing work! You\'re crushing it! 🔥',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Workout Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.access_time_rounded,
                              duration,
                              'Duration',
                            ),
                            _buildStatItem(
                              Icons.fitness_center_rounded,
                              '$exercisesCount',
                              'Exercises',
                            ),
                            _buildStatItem(
                              Icons.local_fire_department_rounded,
                              '$calories',
                              'Calories',
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        _buildWeeklyProgress(userId, programId),
                        const SizedBox(height: 32),
                        _buildStreakCard(streakCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildActionButtons(context),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4A90E2), size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(String userId, String programId) {
    return StreamBuilder<double>(
      stream: DatabaseService().getProgramProgressStream(userId, programId),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;

        // Calculate X of Y
        return FutureBuilder<int>(
          future: DatabaseService()
              .getWorkoutsStream(programId)
              .first
              .then((list) => list.length),
          builder: (context, totalSnapshot) {
            final total = totalSnapshot.data ?? 0;
            final completed = (progress * total).round();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Program Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    Text(
                      '$completed of $total completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2EDBAA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8D5CF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2EDBAA),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Current Streak',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMedium,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            streak <= 1 ? 'First Day' : '$streak-Days',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'View Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
