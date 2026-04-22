import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AssessmentProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isAlternative;

  const AssessmentProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.isAlternative = false,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;

    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: isAlternative 
            ? Colors.white.withOpacity(0.2)
            : AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: isAlternative ? Colors.white : AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
