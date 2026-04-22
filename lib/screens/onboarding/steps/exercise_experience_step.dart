import 'package:azana_sculpt/constants/onboarding_assets.dart';
import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class ExerciseExperienceStep extends StatelessWidget {
  final String selectedExperience;
  final ValueChanged<String> onExperienceChanged;

  const ExerciseExperienceStep({
    super.key,
    required this.selectedExperience,
    required this.onExperienceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      {'label': 'Beginner', 'image': OnboardingAssets.beginner},
      {'label': 'Intermediate', 'image': OnboardingAssets.intermediate},
      {'label': 'Advance', 'image': OnboardingAssets.advance},
      {'label': 'Expert', 'image': OnboardingAssets.expert},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Basic weightlifting exercises?",
          subtitle:
              "Please rate your familiarity with basic weightlifting exercises (e.g., Squats, Deadlifts, Overhead Press).",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final label = level['label'] as String;
                final image = level['image'] as String?;
                final icon = level['icon'] as IconData?;
                final isSelected = selectedExperience == label;

                return GridSelectionCard(
                  imageAsset: image,
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  onTap: () => onExperienceChanged(label),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
