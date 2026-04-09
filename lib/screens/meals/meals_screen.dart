import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  int _activeToggleIndex = 0; // 0 for Meal Plan, 1 for Recipe Book
  String _selectedDay = 'Tue';

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _buildBody() {
    if (_activeToggleIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildTodayPlanCard(),
            const SizedBox(height: 24),
            _buildDaySelector(),
            const SizedBox(height: 24),
            _buildMealList(),
            const SizedBox(height: 40),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildRecipeView(),
            const SizedBox(height: 40),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4847A).withOpacity(0.15),
            const Color(0xFFCDA96E).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4847A).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apple_rounded,
                  color: Color(0xFFD4847A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Plan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'Your personalized nutrition guide',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(0, Icons.restaurant_menu_rounded, 'Meal Plan'),
                ),
                Expanded(
                  child: _buildToggleButton(1, Icons.menu_book_rounded, 'Recipe Book'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(int index, IconData icon, String label) {
    final isActive = _activeToggleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeToggleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppTheme.divider.withOpacity(0.2)) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFFD4847A) : AppTheme.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFFD4847A) : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Plan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Tuesday, Apr 7',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textLight),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('🔥', '1800', 'Calories'),
              _buildMacroItem('💪', '152g', 'Protein'),
              _buildMacroItem('🍎', '185g', 'Carbs'),
              _buildMacroItem('⚡', '58g', 'Fat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String emoji, String value, String label) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Row(
      children: _days.map((day) {
        final isSelected = _selectedDay == day;
        // Keep to only Tue/Wed for screenshot accuracy if desired, 
        // but leaving all days is fine since it scrolls/fits.
        // The screenshot mainly shows Tue Wed with background behind them.
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4847A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD4847A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textLight,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int? _expandedMealIndex;

  Widget _buildMealList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMealCard(
          index: 0,
          title: 'Breakfast',
          time: '7:30 AM',
          cal: '420 cal',
          duration: '5 min',
          emoji: '🌅',
          recipeName: 'Protein Overnight Oats',
          recipeMacros: 'P: 28g   C: 52g   F: 12g',
        ),
        _buildMealCard(
          index: 1,
          title: 'Snack',
          time: '10:30 AM',
          cal: '280 cal',
          duration: '5 min',
          emoji: '🍎',
          recipeName: 'Apple Pencil with Almond Butter', // Placeholder
          recipeMacros: 'P: 8g   C: 25g   F: 15g',
        ),
        _buildMealCard(
          index: 2,
          title: 'Lunch',
          time: '1:00 PM',
          cal: '520 cal',
          duration: '25 min',
          emoji: '☀️',
          recipeName: 'Grilled Chicken Salad', // Placeholder
          recipeMacros: 'P: 45g   C: 30g   F: 20g',
        ),
        _buildMealCard(
          index: 3,
          title: 'Snack',
          time: '4:00 PM',
          cal: '380 cal',
          duration: '10 min',
          emoji: '🍎',
          recipeName: 'Protein Shake & Nuts', // Placeholder
          recipeMacros: 'P: 30g   C: 15g   F: 18g',
        ),
        _buildMealCard(
          index: 4,
          title: 'Dinner',
          time: '7:00 PM',
          cal: '580 cal',
          duration: '30 min',
          emoji: '🌙',
          recipeName: 'Salmon & Quinoa', // Placeholder
          recipeMacros: 'P: 42g   C: 45g   F: 24g',
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required int index,
    required String title,
    required String time,
    required String cal,
    required String duration,
    required String emoji,
    required String recipeName,
    required String recipeMacros,
  }) {
    final isExpanded = _expandedMealIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedMealIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cal,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textLight,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 24),
              _buildExpandedMealDetails(recipeName, recipeMacros),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMealDetails(String name, String macros) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        _buildMacrosText(macros),
        const SizedBox(height: 20),
        _buildSectionHeader(Icons.restaurant_rounded, 'Ingredients'),
        const SizedBox(height: 12),
        _buildBulletPoint('1/2 cup rolled oats'),
        _buildBulletPoint('1 scoop vanilla protein powder'),
        _buildBulletPoint('1 cup almond milk'),
        _buildBulletPoint('1 tbsp chia seeds'),
        _buildBulletPoint('1/2 banana, sliced'),
        _buildBulletPoint('1 tbsp almond butter'),
        _buildBulletPoint('Handful of berries'),
        const SizedBox(height: 20),
        _buildSectionHeader(Icons.access_time_rounded, 'Instructions'),
        const SizedBox(height: 12),
        _buildNumberedPoint('1', 'Mix oats, protein powder, almond milk, and chia seeds in a jar'),
        _buildNumberedPoint('2', 'Refrigerate overnight or for at least 4 hours'),
        _buildNumberedPoint('3', 'In the morning, top with banana slices, almond butter, and berries'),
        _buildNumberedPoint('4', 'Enjoy cold or heat for 30 seconds in microwave'),
      ],
    );
  }

  Widget _buildMacrosText(String macros) {
    // Parse "P: 28g   C: 52g   F: 12g"
    final parts = macros.split('   ');
    if (parts.length < 3) return Text(macros);

    return Row(
      children: [
        _buildColoredMacro(parts[0], const Color(0xFFD4847A)),
        const SizedBox(width: 12),
        _buildColoredMacro(parts[1], const Color(0xFFCDA96E)),
        const SizedBox(width: 12),
        _buildColoredMacro(parts[2], const Color(0xFFE5A6A6)),
      ],
    );
  }

  Widget _buildColoredMacro(String macroString, Color color) {
    return Text(
      macroString,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD4847A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFD4847A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFFCDA96E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protein Overnight Oats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('🔥', '420', 'Calories'),
              _buildMacroItem('💪', '28g', 'Protein'),
              _buildMacroItem('🍎', '52g', 'Carbs'),
              _buildMacroItem('⚡', '12g', 'Fat'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppTheme.textMedium),
              const SizedBox(width: 6),
              const Text(
                'Prep time: 5 min',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(Icons.restaurant_rounded, 'Ingredients'),
          const SizedBox(height: 16),
          _buildBulletPoint('1/2 cup rolled oats'),
          _buildBulletPoint('1 scoop vanilla protein powder'),
          _buildBulletPoint('1 cup almond milk'),
          _buildBulletPoint('1 tbsp chia seeds'),
          _buildBulletPoint('1/2 banana, sliced'),
          _buildBulletPoint('1 tbsp almond butter'),
          _buildBulletPoint('Handful of berries'),
          const SizedBox(height: 32),
          _buildSectionHeader(Icons.access_time_rounded, 'Instructions'),
          const SizedBox(height: 16),
          _buildNumberedPoint('1', 'Mix oats, protein powder, almond milk, and chia seeds in a jar'),
          _buildNumberedPoint('2', 'Refrigerate overnight or for at least 4 hours'),
          _buildNumberedPoint('3', 'In the morning, top with banana slices, almond butter, and berries'),
          _buildNumberedPoint('4', 'Enjoy cold or heat for 30 seconds in microwave'),
        ],
      ),
    );
  }
}

