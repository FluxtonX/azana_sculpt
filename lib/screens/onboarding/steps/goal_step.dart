import 'package:azana_sculpt/constants/onboarding_assets.dart';
import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class GoalStep extends StatelessWidget {
  final String selectedGoal;
  final ValueChanged<String> onGoalChanged;

  const GoalStep({
    super.key,
    required this.selectedGoal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final goals = [
      {'label': 'Lose Weight', 'image': OnboardingAssets.loseWeight},
      {'label': 'Build Muscle', 'icon': Icons.fitness_center_rounded},
      {'label': 'Boost Endurance', 'image': OnboardingAssets.boostEndurance},
      {'label': 'Improve Health', 'image': OnboardingAssets.improveHealth},
      {'label': 'Flexibility', 'image': OnboardingAssets.flexibility},
      {'label': 'Sport Performance', 'image': OnboardingAssets.sportPerformance},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "What's your fitness goal?",
          subtitle: "Select your primary goal to personalize your plan",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final label = goal['label'] as String;
                final image = goal['image'] as String?;
                final icon = goal['icon'] as IconData?;
                final isSelected = selectedGoal == label;

                return GridSelectionCard(
                  imageAsset: image,
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  onTap: () => onGoalChanged(label),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
