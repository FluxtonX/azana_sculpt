import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AssessmentProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AssessmentProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;

    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * progress,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
