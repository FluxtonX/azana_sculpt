// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _beforePath;
  String? _afterPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _beforePath = prefs.getString('before_photo');
      _afterPath = prefs.getString('after_photo');
    });
  }

  Future<void> _pickImage(bool isBefore) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        if (isBefore) {
          await prefs.setString('before_photo', image.path);
          setState(() {
            _beforePath = image.path;
          });
        } else {
          await prefs.setString('after_photo', image.path);
          setState(() {
            _afterPath = image.path;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isBefore ? "Before" : "After"} photo updated!'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
      }
    }
  }

  void _showAddPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Progress Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                title: const Text(
                  'Update "Before" Photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('The start of your journey'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EB87D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2EB87D),
                  ),
                ),
                title: const Text(
                  'Update "After" Photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('See your results'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(false);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = AuthService().currentUser?.uid ?? '';

    return StreamBuilder<UserModel?>(
      stream: DatabaseService().userProfileStream(uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getWeightLogsStream(uid),
          builder: (context, weightSnapshot) {
            final weightLogs = weightSnapshot.data ?? [];
            final metrics = _ProgressMetrics.from(
              user: user,
              weightLogs: weightLogs,
            );

            return StreamBuilder<int>(
              stream: DatabaseService().getTotalCompletedWorkoutsCountStream(
                uid,
              ),
              builder: (context, workoutCountSnapshot) {
                final completedWorkoutsCount = workoutCountSnapshot.data ?? 0;
                final fitnessScore = (user?.fitnessScore ?? 0).round();

                return Scaffold(
                  backgroundColor: const Color(0xFFF6F7FB),
                  appBar: AppBar(
                    title: const Text('Progress'),
                    automaticallyImplyLeading: false,
                    centerTitle: false,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: Colors.white,
                    titleTextStyle: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 26),
                        _buildStatsRow(metrics, completedWorkoutsCount),
                        const SizedBox(height: 24),
                        _buildWeightProgressSection(weightLogs, metrics),
                        const SizedBox(height: 24),
                        _buildProgressPhotosSection(metrics),
                        const SizedBox(height: 24),
                        _buildGoalsProgressSection(
                          user,
                          metrics,
                          completedWorkoutsCount,
                          fitnessScore,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRow(_ProgressMetrics metrics, int completedWorkouts) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.trending_down_rounded,
            metrics.changeLabel,
            metrics.isGainGoal ? 'Gained' : 'Lost',
            const Color(0xFFD4847A),
            const Color(0xFFFFF1EE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.calendar_month_rounded,
            '${metrics.daysTracked}',
            'Days',
            const Color(0xFFD4847A),
            const Color(0xFFFFF1EE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.flash_on_rounded,
            '$completedWorkouts',
            'Workouts',
            const Color(0xFFFF9800),
            const Color(0xFFFFF5E7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color accentColor,
    Color iconBg,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Transform.translate(
          offset: Offset(0, 14 * (1 - animatedValue)),
          child: Opacity(opacity: animatedValue, child: child),
        );
      },
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textDark.withOpacity(0.035),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 22),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressSection(
    List<Map<String, dynamic>> weightLogs,
    _ProgressMetrics metrics,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 18),
          _buildWeightInsight(metrics),
          const SizedBox(height: 28),
          SizedBox(height: 250, child: _buildPremiumLineChart(weightLogs)),
        ],
      ),
    );
  }

  Widget _buildWeightInsight(_ProgressMetrics metrics) {
    return Row(
      children: [
        _buildMiniMetric(
          'Start',
          metrics.startWeightLabel,
          Icons.flag_rounded,
          AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _buildMiniMetric(
          'Current',
          metrics.currentWeightLabel,
          Icons.monitor_weight_rounded,
          const Color(0xFF2EB87D),
        ),
        const SizedBox(width: 10),
        _buildMiniMetric(
          'Change',
          metrics.changeLabel,
          metrics.isGainGoal
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 9),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLineChart(List<Map<String, dynamic>> weightLogs) {
    if (weightLogs.length < 2) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
        ),
        child: const Center(
          child: Text(
            'Add at least two weight logs to see your trend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final spots = weightLogs.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['weight'] as num).toDouble(),
      );
    }).toList();

    final minWeight = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = ((maxWeight - minWeight).abs() * 0.35).clamp(0.8, 2.2);
    final minY = minWeight - padding;
    final maxY = maxWeight + padding;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final animatedSpots = spots.map((spot) {
          return FlSpot(spot.x, minY + ((spot.y - minY) * value));
        }).toList();

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: ((maxY - minY) / 3).clamp(0.5, 5),
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFE9EAEE),
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: const Color(0xFFF0F1F4),
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: ((maxY - minY) / 3).clamp(0.5, 5),
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: (spots.length / 4).ceilToDouble().clamp(1, 4),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= weightLogs.length) {
                      return const SizedBox.shrink();
                    }
                    final rawDate =
                        weightLogs[index]['loggedAt']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatShortDate(rawDate),
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Color(0xFFA9ABB2), width: 1.2),
                bottom: BorderSide(color: Color(0xFFA9ABB2), width: 1.2),
              ),
            ),
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: animatedSpots,
                isCurved: false,
                color: const Color(0xFFD98D92),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFFD98D92),
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD98D92).withOpacity(0.16),
                      const Color(0xFFD98D92).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} kg',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Widget _buildProgressPhotosSection(_ProgressMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              InkWell(
                onTap: _showAddPhotoOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppTheme.textDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildPhotoCard(
                  label: 'Before',
                  imagePath: _beforePath,
                  date: metrics.startDateLabel,
                  weight: metrics.startWeightLabel,
                  isBefore: true,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildPhotoCard(
                  label: 'After',
                  imagePath: _afterPath,
                  date: metrics.currentDateLabel,
                  weight: metrics.currentWeightLabel,
                  isBefore: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String label,
    required String? imagePath,
    required String date,
    required String weight,
    required bool isBefore,
  }) {
    final imageExists = imagePath != null && File(imagePath).existsSync();
    return Column(
      children: [
        InkWell(
          onTap: () => _pickImage(isBefore),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 166,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: imageExists
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isBefore
                          ? const [Color(0xFFF8D7D2), Color(0xFFEFD197)]
                          : const [Color(0xFFE8C87D), Color(0xFFEFDCA5)],
                    ),
              image: imageExists
                  ? DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageExists
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.textMedium.withOpacity(0.7),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        date,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          weight,
          style: const TextStyle(
            color: AppTheme.textMedium,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsProgressSection(
    UserModel? user,
    _ProgressMetrics metrics,
    int workouts,
    int fitnessScore,
  ) {
    final goals = _buildDynamicGoals(user, metrics, workouts, fitnessScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goals Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          ...goals.expand(
            (goal) => [
              _buildGoalItem(goal),
              if (goal != goals.last) const SizedBox(height: 22),
            ],
          ),
        ],
      ),
    );
  }

  List<_GoalProgress> _buildDynamicGoals(
    UserModel? user,
    _ProgressMetrics metrics,
    int workouts,
    int fitnessScore,
  ) {
    final goal = (user?.fitnessGoal ?? '').toLowerCase();
    final weightTarget = 5.0;
    final weightProgress = (metrics.absoluteChange / weightTarget).clamp(
      0.0,
      1.0,
    );
    final strengthTarget = goal.contains('muscle') || goal.contains('gain')
        ? 75
        : 100;
    final strengthProgress = (workouts / strengthTarget).clamp(0.0, 1.0);
    final scoreProgress = (fitnessScore / 100).clamp(0.0, 1.0);

    return [
      _GoalProgress(
        title: metrics.isGainGoal ? 'Healthy Weight Gain' : 'Weight Loss',
        progress: weightProgress,
        subtitle:
            'Target: ${weightTarget.toStringAsFixed(0)} kg · ${(weightTarget - metrics.absoluteChange).clamp(0, weightTarget).toStringAsFixed(1)} kg to go',
        color: const Color(0xFFD4847A),
      ),
      _GoalProgress(
        title: 'Build Strength',
        progress: strengthProgress,
        subtitle:
            'Target: $strengthTarget workouts · ${(strengthTarget - workouts).clamp(0, strengthTarget)} to go',
        color: const Color(0xFFE2B769),
      ),
      _GoalProgress(
        title: 'Fitness Score',
        progress: scoreProgress,
        subtitle: 'Based on workouts, consistency, profile data and goals',
        color: const Color(0xFF86A96F),
      ),
    ];
  }

  Widget _buildGoalItem(_GoalProgress goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              goal.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '${(goal.progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: goal.progress),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: const Color(0xFFF1F1F3),
                valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          goal.subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  String _formatShortDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}';
  }
}

class _ProgressMetrics {
  final double startWeight;
  final double currentWeight;
  final String unit;
  final DateTime? startDate;
  final DateTime? currentDate;
  final bool isGainGoal;

  const _ProgressMetrics({
    required this.startWeight,
    required this.currentWeight,
    required this.unit,
    required this.startDate,
    required this.currentDate,
    required this.isGainGoal,
  });

  factory _ProgressMetrics.from({
    required UserModel? user,
    required List<Map<String, dynamic>> weightLogs,
  }) {
    final profileWeight = double.tryParse(user?.weight ?? '') ?? 0;
    final unit = user?.weightUnit ?? 'kg';
    final isGainGoal = (user?.fitnessGoal ?? '').toLowerCase().contains('gain');

    if (weightLogs.isEmpty) {
      return _ProgressMetrics(
        startWeight: profileWeight,
        currentWeight: profileWeight,
        unit: unit,
        startDate: user?.createdAt,
        currentDate: DateTime.now(),
        isGainGoal: isGainGoal,
      );
    }

    final first = weightLogs.first;
    final last = weightLogs.last;

    return _ProgressMetrics(
      startWeight: (first['weight'] as num?)?.toDouble() ?? profileWeight,
      currentWeight: (last['weight'] as num?)?.toDouble() ?? profileWeight,
      unit: first['unit']?.toString() ?? unit,
      startDate: DateTime.tryParse(first['loggedAt']?.toString() ?? ''),
      currentDate: DateTime.tryParse(last['loggedAt']?.toString() ?? ''),
      isGainGoal: isGainGoal,
    );
  }

  double get signedChange =>
      isGainGoal ? currentWeight - startWeight : startWeight - currentWeight;

  double get absoluteChange => signedChange.clamp(0.0, 999.0);

  int get daysTracked {
    final start = startDate;
    final end = currentDate ?? DateTime.now();
    if (start == null) return 0;
    return end.difference(start).inDays.abs().clamp(0, 9999);
  }

  String get changeLabel {
    final prefix = isGainGoal
        ? (signedChange >= 0 ? '+' : '-')
        : (signedChange >= 0 ? '-' : '+');
    return '$prefix${absoluteChange.toStringAsFixed(1)}$unit';
  }

  String get startWeightLabel =>
      startWeight > 0 ? '${startWeight.toStringAsFixed(1)} $unit' : '--';

  String get currentWeightLabel =>
      currentWeight > 0 ? '${currentWeight.toStringAsFixed(1)} $unit' : '--';

  String get startDateLabel => _dateLabel(startDate);
  String get currentDateLabel => _dateLabel(currentDate);

  static String _dateLabel(DateTime? date) {
    if (date == null) return 'No date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _GoalProgress {
  final String title;
  final double progress;
  final String subtitle;
  final Color color;

  const _GoalProgress({
    required this.title,
    required this.progress,
    required this.subtitle,
    required this.color,
  });
}
