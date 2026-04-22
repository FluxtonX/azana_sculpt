import 'package:azana_sculpt/constants/onboarding_assets.dart';
import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class SupplementsGridStep extends StatelessWidget {
  final List<String> selectedSupplements;
  final ValueChanged<List<String>> onSupplementsChanged;

  const SupplementsGridStep({
    super.key,
    required this.selectedSupplements,
    required this.onSupplementsChanged,
  });

  void _toggleSupplement(String supplement) {
    final updated = List<String>.from(selectedSupplements);
    if (updated.contains(supplement)) {
      updated.remove(supplement);
    } else {
      updated.add(supplement);
    }
    onSupplementsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final supplements = [
      {'label': 'Protein', 'image': OnboardingAssets.protein},
      {'label': 'Creatine', 'image': OnboardingAssets.creatine},
      {'label': 'BCAA', 'image': OnboardingAssets.bcaa},
      {'label': 'Vitamins', 'image': OnboardingAssets.vitamins},
      {'label': 'Pre-Workout', 'image': OnboardingAssets.preWorkout},
      {'label': 'Omega-3', 'image': OnboardingAssets.omega3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Which supplements?",
          subtitle: "Select all that apply",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.9,
            ),
            itemCount: supplements.length,
            itemBuilder: (context, index) {
              final item = supplements[index];
              final label = item['label'] as String;
              final image = item['image'] as String?;
              final icon = item['icon'] as IconData?;
              final isSelected = selectedSupplements.contains(label);

              return GridSelectionCard(
                imageAsset: image,
                icon: icon,
                label: label,
                isSelected: isSelected,
                onTap: () => _toggleSupplement(label),
              );
            },
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
