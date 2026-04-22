import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';
import '../widgets/arc_slider.dart';

class ActivityStep extends StatelessWidget {
  final int activityLevel;
  final ValueChanged<int> onActivityChanged;

  const ActivityStep({
    super.key,
    required this.activityLevel,
    required this.onActivityChanged,
  });

  String _activityLabel(int level) {
    switch (level) {
      case 1:
        return 'Sedentary';
      case 2:
        return 'Lightly Active';
      case 3:
        return 'Moderately Active';
      case 4:
        return 'Very Active';
      case 5:
        return 'Extremely Active';
      default:
        return 'Moderately Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Describe your current activity level?",
          subtitle: "Slide to indicate your current fitness level",
        ),
        const SizedBox(height: 8),
        // Drag hint
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Drag to adjust',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Arc Slider + Value Display
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Arc Slider — pushed to bottom-left, overflowing off-screen
              Positioned(
                left: 100,
                bottom: 10,
                child: Transform.rotate(
                  angle: -0.57, // radians
                  child: ArcSlider(
                    min: 1,
                    max: 5,
                    value: activityLevel,
                    onChanged: onActivityChanged,
                  ),
                ),
              ),
              // Value + Label (right-aligned, bottom)
              Positioned(
                right: 24,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activityLevel.toString(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 140,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary.withOpacity(0.4),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activityLabel(activityLevel),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
