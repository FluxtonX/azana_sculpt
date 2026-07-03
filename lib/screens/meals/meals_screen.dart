import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../models/meal_model.dart';
import 'pdf_meal_plan_viewer_screen.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with SingleTickerProviderStateMixin {
  int _activeToggleIndex = 0; // 0 for Meal Plan, 1 for Recipe Book
  String _selectedDay = 'Mon';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late final AnimationController _nutritionAnimationController;

  @override
  void initState() {
    super.initState();
    // Default to current day
    final now = DateTime.now();
    _selectedDay = _days[now.weekday - 1];
    _nutritionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _nutritionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: uid.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : StreamBuilder<MealPlanPdf?>(
                stream: DatabaseService().getMealPlanPdfStream(uid),
                builder: (context, pdfSnapshot) {
                  final pdf = pdfSnapshot.data;

                  return StreamBuilder<DailyMealPlan?>(
                    stream: DatabaseService().getMealPlanStream(
                      uid,
                      _selectedDay,
                    ),
                    builder: (context, snapshot) {
                      final plan = snapshot.data;
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting ||
                          pdfSnapshot.connectionState ==
                              ConnectionState.waiting;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          _buildAppBar(),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildToggle(),
                                if (_activeToggleIndex == 0) ...[
                                  if (isLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(50.0),
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primary,
                                      ),
                                    )
                                  else if (pdf != null &&
                                      pdf.downloadUrl.isNotEmpty)
                                    _buildPdfMealPlanContent(pdf)
                                  else if (plan == null)
                                    _buildEmptyState()
                                  else
                                    _buildMealPlanContent(plan),
                                ] else
                                  _buildRecipeBookContent(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.surface,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Nutrition',
        style: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF2E1E1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildToggleItem(0, 'Meal Plan'),
          _buildToggleItem(1, 'Recipe Book'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(int index, String title) {
    final bool isActive = _activeToggleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeToggleIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isActive ? Colors.white : AppTheme.textMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No meal plan for $_selectedDay',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later or message your coach.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 40),
          _buildDaySelector(),
        ],
      ),
    );
  }

  Widget _buildMealPlanContent(DailyMealPlan plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildSummaryCard(plan),
          const SizedBox(height: 24),
          _buildDaySelector(),
          const SizedBox(height: 24),
          _buildMealList(plan.meals),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPdfMealPlanContent(MealPlanPdf pdf) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coach Meal Plan',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pdf.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildAnimatedNutritionPreview(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdfPlan(pdf),
                    icon: const Icon(Icons.visibility_rounded),
                    label: Text(
                      'View Meal Plan',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNutritionPreview() {
    return AnimatedBuilder(
      animation: _nutritionAnimationController,
      builder: (context, child) {
        final progress = _nutritionAnimationController.value;
        final pulse = 0.5 + (math.sin(progress * math.pi * 2) * 0.5);

        return Container(
          height: 238,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF7F4),
                AppTheme.primary.withOpacity(0.09),
                AppTheme.primaryLight.withOpacity(0.26),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 18 + (pulse * 8),
                right: 24,
                child: _buildFloatingFoodIcon(
                  Icons.local_dining_rounded,
                  AppTheme.primary,
                  progress,
                ),
              ),
              Positioned(
                top: 66 - (pulse * 7),
                left: 24,
                child: _buildFloatingFoodIcon(
                  Icons.eco_rounded,
                  AppTheme.primaryDark.withOpacity(0.76),
                  progress + 0.18,
                ),
              ),
              Positioned(
                bottom: 54 + (pulse * 6),
                right: 34,
                child: _buildFloatingFoodIcon(
                  Icons.water_drop_rounded,
                  const Color(0xFF7E9DB4),
                  progress + 0.36,
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: 1 + (pulse * 0.025),
                  child: SizedBox(
                    width: 156,
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: progress * math.pi * 2,
                          child: CustomPaint(
                            size: const Size(156, 156),
                            painter: _MacroRingPainter(progress: progress),
                          ),
                        ),
                        Container(
                          width: 106,
                          height: 106,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.16),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppTheme.primary,
                                size: 32 + (pulse * 3),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Plan',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.9)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your nutrition plan is ready',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildAnimatedMacroBar(
                            'Protein',
                            0.82,
                            AppTheme.primary,
                            progress,
                          ),
                          const SizedBox(width: 8),
                          _buildAnimatedMacroBar(
                            'Carbs',
                            0.68,
                            AppTheme.primaryLight,
                            progress + 0.16,
                          ),
                          const SizedBox(width: 8),
                          _buildAnimatedMacroBar(
                            'Fats',
                            0.54,
                            AppTheme.primaryDark.withOpacity(0.68),
                            progress + 0.32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingFoodIcon(IconData icon, Color color, double progress) {
    final offset = math.sin(progress * math.pi * 2) * 6;

    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.76),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildAnimatedMacroBar(
    String label,
    double target,
    Color color,
    double progress,
  ) {
    final animatedValue =
        (target * (0.74 + (math.sin(progress * math.pi * 2) * 0.08)))
            .clamp(0.1, 1.0)
            .toDouble();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: animatedValue,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openPdfPlan(MealPlanPdf pdf) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfMealPlanViewerScreen(pdf: pdf)),
    );
  }

  Widget _buildSummaryCard(DailyMealPlan plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('🔥', plan.targetCalories, 'Calories'),
              _buildMacroItem('💪', plan.targetProtein, 'Protein'),
              _buildMacroItem('🍎', plan.targetCarbs, 'Carbs'),
              _buildMacroItem('⚡', plan.targetFat, 'Fat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _days.map((day) {
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : const Color(0xFFF2E1E1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                day,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textMedium,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealList(List<MealModel> meals) {
    return Column(children: meals.map((meal) => _buildMealCard(meal)).toList());
  }

  Widget _buildMealCard(MealModel meal) {
    return GestureDetector(
      onTap: () => _showMealDetail(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF2E1E1).withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  _getMealEmoji(meal.type),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.type,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    meal.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${meal.time} • ${meal.calories} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  String _getMealEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍲';
    }
  }

  void _showMealDetail(MealModel meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        meal.type,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      meal.time,
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  meal.title,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailStat(Icons.timer_outlined, meal.prepTime),
                    _buildDetailStat(
                      Icons.local_fire_department_outlined,
                      '${meal.calories} kcal',
                    ),
                    _buildDetailStat(
                      Icons.restaurant_outlined,
                      '${meal.protein}g protein',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Ingredients'),
                const SizedBox(height: 12),
                ...meal.ingredients.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(ing),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Instructions'),
                const SizedBox(height: 12),
                ...meal.instructions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMedium),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRecipeBookContent() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 60,
            color: AppTheme.primaryLight,
          ),
          const SizedBox(height: 20),
          const Text(
            'Recipe Book Coming Soon!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Explore thousands of healthy recipes.',
            style: TextStyle(color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;

  const _MacroRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 9;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.78);

    canvas.drawCircle(center, radius, basePaint);

    final segments = [
      (color: AppTheme.primary, start: -math.pi / 2, sweep: math.pi * 0.78),
      (
        color: AppTheme.primaryLight,
        start: math.pi * 0.34,
        sweep: math.pi * 0.52,
      ),
      (
        color: AppTheme.primaryDark.withOpacity(0.70),
        start: math.pi * 0.94,
        sweep: math.pi * 0.38,
      ),
    ];

    for (final segment in segments) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = segment.color.withOpacity(0.86);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segment.start + (progress * 0.22),
        segment.sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
