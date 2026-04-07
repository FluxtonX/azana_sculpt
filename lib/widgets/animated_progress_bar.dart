// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Animated progress bar that plays an entrance animation
/// and shows a subtle glow when at 100%.
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final Duration duration;
  final bool showGlowAtComplete;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 900),
    this.showGlowAtComplete = true,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppTheme.primary;
    final isComplete = value >= 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        return Container(
          decoration: isComplete && showGlowAtComplete
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: animValue,
              minHeight: height,
              backgroundColor:
                  backgroundColor ?? AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.accent : barColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
