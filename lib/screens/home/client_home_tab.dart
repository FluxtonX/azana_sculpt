import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/workout_models.dart';
import '../../services/database_service.dart';
import '../coach/chat_screen.dart';
import '../coaches/all_coaches_screen.dart';
import '../workouts/exercise_detail_screen.dart';

class ClientHomeTab extends StatefulWidget {
  final UserModel user;
  const ClientHomeTab({super.key, required this.user});

  @override
  State<ClientHomeTab> createState() => _ClientHomeTabState();
}

class _ClientHomeTabState extends State<ClientHomeTab> {
  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF file.')),
        );
      }
    }
  }

  void _contactCoach() {
    final coachId = widget.user.coachId;
    if (coachId != null && coachId.isNotEmpty) {
      final chatId = '${widget.user.uid}_$coachId';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUser: UserModel(
              uid: coachId,
              email: '',
              fullName: 'My Coach',
              role: 'coach',
            ),
            currentUserId: widget.user.uid,
          ),
        ),
      );
    } else {
      // If no coach assigned yet, browse coaches
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllCoachesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.fullName ?? 'Member';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: DatabaseService().getClientAssignmentStream(widget.user.uid),
          builder: (context, snapshot) {
            final assignedProgram =
                snapshot.data?['assignedProgram'] as Map<String, dynamic>?;
            final assignedMealPlan =
                snapshot.data?['assignedMealPlan'] as Map<String, dynamic>?;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(name),
                  const SizedBox(height: 20),

                  // Contact Coach Quick Action Banner
                  _buildContactCoachBanner(),
                  const SizedBox(height: 28),

                  // Today's Workout Section
                  _buildTodaysWorkoutSection(assignedProgram),
                  const SizedBox(height: 28),

                  // Weekly Workout Schedule (Day by day lock/unlock)
                  if (assignedProgram != null) ...[
                    _buildWeeklyScheduleSection(assignedProgram),
                    const SizedBox(height: 28),
                  ],

                  // Meal Plan Section
                  _buildMealPlanSection(assignedMealPlan),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'A',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCoachBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.15),
            AppTheme.primaryLight.withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Guidance?',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'Message your coach anytime',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _contactCoach,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Contact',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysWorkoutSection(Map<String, dynamic>? assignedProgram) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              "Today's Workout",
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignedProgram == null)
          _buildNoAssignmentCard(
            title: 'No Workout Assigned Yet',
            subtitle:
                'Your coach will create a custom workout plan tailored specifically for you.',
            icon: Icons.lock_outline,
          )
        else
          _buildActiveTodaysWorkoutCard(assignedProgram),
      ],
    );
  }

  Widget _buildActiveTodaysWorkoutCard(Map<String, dynamic> assignedProgram) {
    final programId = assignedProgram['programId'] as String? ?? '';
    final programTitle =
        assignedProgram['programTitle'] as String? ?? 'Custom Workout';
    final note = assignedProgram['note'] as String? ?? '';
    final startDateStr = assignedProgram['startDate'] as String?;
    final startDate = startDateStr != null
        ? DateTime.tryParse(startDateStr) ?? DateTime.now()
        : DateTime.now();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getAssignedWorkoutsWithLockStatus(
        programId: programId,
        startDate: startDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workoutEntries = snapshot.data ?? [];
        if (workoutEntries.isEmpty) {
          return _buildNoAssignmentCard(
            title: programTitle,
            subtitle: 'No workout sessions found in this program.',
            icon: Icons.fitness_center,
          );
        }

        // Find today's workout or next unlocked workout
        Map<String, dynamic>? todaysEntry;
        try {
          todaysEntry = workoutEntries.firstWhere(
            (e) => e['isToday'] == true,
          );
        } catch (_) {
          // If no specific today entry, find latest unlocked
          try {
            todaysEntry = workoutEntries.lastWhere(
              (e) => e['isUnlocked'] == true,
            );
          } catch (_) {
            todaysEntry = workoutEntries.first;
          }
        }

        final workout = todaysEntry['workout'] as WorkoutSession?;
        final isUnlocked = (todaysEntry['isUnlocked'] as bool?) ?? false;
        final dayNumber = (todaysEntry['dayNumber'] as int?) ?? 1;

        if (workout == null) {
          return _buildNoAssignmentCard(
            title: programTitle,
            subtitle: 'Rest day or workouts complete.',
            icon: Icons.check_circle_outline,
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DAY $dayNumber',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workout.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                programTitle,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textLight,
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildWorkoutMetric(
                    Icons.timer_outlined,
                    workout.totalDuration.isNotEmpty
                        ? workout.totalDuration
                        : '45 mins',
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutMetric(
                    Icons.format_list_bulleted,
                    '${workout.exercises.length} exercises',
                  ),
                  const SizedBox(width: 16),
                  _buildWorkoutMetric(
                    Icons.local_fire_department_outlined,
                    '${workout.caloriesBurned > 0 ? workout.caloriesBurned : 350} kcal',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUnlocked
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(
                                folderName: workout.title,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isUnlocked ? 'Start Today\'s Workout' : 'Available Tomorrow',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyScheduleSection(Map<String, dynamic> assignedProgram) {
    final programId = assignedProgram['programId'] as String? ?? '';
    final startDateStr = assignedProgram['startDate'] as String?;
    final startDate = startDateStr != null
        ? DateTime.tryParse(startDateStr) ?? DateTime.now()
        : DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              "Your Weekly Schedule",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Workouts unlock day-by-day based on your plan.",
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getAssignedWorkoutsWithLockStatus(
            programId: programId,
            startDate: startDate,
          ),
          builder: (context, snapshot) {
            final workoutEntries = snapshot.data ?? [];
            if (workoutEntries.isEmpty) {
              return const SizedBox.shrink();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workoutEntries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = workoutEntries[index];
                final workout = entry['workout'] as WorkoutSession;
                final isUnlocked = entry['isUnlocked'] as bool;
                final isToday = entry['isToday'] as bool;
                final dayNumber = entry['dayNumber'] as int;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primary.withOpacity(0.08)
                        : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isToday
                          ? AppTheme.primary
                          : AppTheme.divider,
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            isUnlocked ? Icons.play_arrow : Icons.lock_outline,
                            size: 20,
                            color: isUnlocked
                                ? AppTheme.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Day $dayNumber',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked
                                        ? AppTheme.primary
                                        : AppTheme.textLight,
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'TODAY',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              workout.title,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isUnlocked
                                    ? AppTheme.textDark
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppTheme.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseDetailScreen(
                                  folderName: workout.title,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Text(
                          'Locked',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealPlanSection(Map<String, dynamic>? assignedMealPlan) {
    final title = assignedMealPlan?['title'] as String?;
    final pdfUrl = assignedMealPlan?['pdfUrl'] as String?;
    final note = assignedMealPlan?['note'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              "Your Meal Plan",
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignedMealPlan == null || pdfUrl == null || pdfUrl.isEmpty)
          _buildNoAssignmentCard(
            title: 'No Meal Plan Assigned',
            subtitle:
                'Your coach will upload a custom meal plan tailored to your nutritional needs.',
            icon: Icons.restaurant,
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: AppTheme.accent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? 'Custom Nutrition Plan',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            'Personalized PDF Guide',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(pdfUrl),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View Meal Plan (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoAssignmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textLight.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _contactCoach,
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Ask Coach'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutMetric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
