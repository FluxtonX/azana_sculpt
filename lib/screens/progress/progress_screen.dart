// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../widgets/animated_progress_bar.dart';
import '../../widgets/photo_comparison_slider.dart';

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
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
                  child: const Icon(Icons.history_rounded, color: AppTheme.primary),
                ),
                title: const Text('Update "Before" Photo', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2EB87D)),
                ),
                title: const Text('Update "After" Photo', style: TextStyle(fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Progress'),
        automaticallyImplyLeading: false,
        centerTitle: false,
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
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildMotivationalMessage(),
            const SizedBox(height: 24),
            _buildWeightProgressSection(),
            const SizedBox(height: 24),
            _buildProgressPhotosSection(),
            const SizedBox(height: 24),
            _buildGoalsProgressSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3F0), Color(0xFFFFF8EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          const Text('🌟', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Look how far you\'ve come!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '2.5kg down in just 75 days. Your dedication is showing. Keep going! 💪',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.trending_down_rounded, '-2.5kg', 'Lost', const Color(0xFF5B8DEF))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.calendar_today_rounded, '75', 'Days', const Color(0xFF2EB87D))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.flash_on_rounded, '58', 'Workouts', AppTheme.primary)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildWeightProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jan 2026 – Now',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: _buildPremiumLineChart(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Jan 15', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text('Feb 1', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text('Feb 15', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text('Mar 1', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text('Mar 30', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.divider.withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 4,
        minY: 64,
        maxY: 69,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 68.0),
              FlSpot(1, 67.2),
              FlSpot(2, 66.8),
              FlSpot(3, 65.9),
              FlSpot(4, 65.5),
            ],
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: AppTheme.primary,
                strokeWidth: 2.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.22),
                  AppTheme.primary.withOpacity(0.0),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildProgressPhotosSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              InkWell(
                onTap: _showAddPhotoOptions,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.textDark),
                      SizedBox(width: 6),
                      Text(
                        'Add Photo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag the handle to compare your transformation.',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 20),
          PhotoComparisonSlider(
            height: 210,
            beforeWidget: _beforePath != null
                ? Image.file(File(_beforePath!), fit: BoxFit.cover)
                : _buildPhotoPlaceholder('Before', true),
            afterWidget: _afterPath != null
                ? Image.file(File(_afterPath!), fit: BoxFit.cover)
                : _buildPhotoPlaceholder('After', false),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String label, bool isBefore) {
    return Container(
      decoration: BoxDecoration(
        gradient: isBefore ? AppTheme.primaryGradient : AppTheme.splashGradient,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_rounded, color: Colors.white60, size: 36),
          const SizedBox(height: 8),
          Text(
            'No $label Photo\nTap "Add Photo"',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goals Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),
          _buildGoalItem('Weight Loss', 0.50, 'Target: 5 kg · 2.5 kg to go'),
          const SizedBox(height: 22),
          _buildGoalItem('Build Strength', 0.58, 'Target: 100 workouts · 42 to go'),
          const SizedBox(height: 22),
          _buildGoalItem('Improve Endurance', 0.70, 'Target: 10km run · Looking strong!'),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, double progress, String target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: progress >= 1.0
                    ? AppTheme.accentLight.withOpacity(0.25)
                    : AppTheme.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0 ? AppTheme.accent : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedProgressBar(
          value: progress,
          height: 8,
          showGlowAtComplete: true,
        ),
        const SizedBox(height: 6),
        Text(target, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }
}
