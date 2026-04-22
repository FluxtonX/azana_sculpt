import 'package:azana_sculpt/constants/onboarding_assets.dart';
import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class EquipmentStep extends StatelessWidget {
  final List<String> selectedEquipment;
  final ValueChanged<List<String>> onEquipmentChanged;

  const EquipmentStep({
    super.key,
    required this.selectedEquipment,
    required this.onEquipmentChanged,
  });

  void _toggleEquipment(String equipment) {
    final updated = List<String>.from(selectedEquipment);

    // Handle mutually exclusive options if needed
    if (equipment == "None" || equipment == "Bodyweight Only") {
      updated.clear();
      updated.add(equipment);
    } else {
      updated.remove("None");
      updated.remove("Bodyweight Only");
      if (updated.contains(equipment)) {
        updated.remove(equipment);
      } else {
        updated.add(equipment);
      }
    }

    onEquipmentChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final equipmentOptions = [
      {'label': 'Gym Membership', 'image': OnboardingAssets.gymMembership},
      {'label': 'Home Equipment', 'image': OnboardingAssets.homeEquipment},
      {'label': 'Cardio Machines', 'image': OnboardingAssets.cardioMachines},
      {'label': 'Bodyweight Only', 'image': OnboardingAssets.bodyweightOnly},
      {'label': 'Park', 'image': OnboardingAssets.park},
      {'label': 'None', 'image': OnboardingAssets.none},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Your gym equipment?",
          subtitle: "What equipment do you have access to for your workouts?",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: equipmentOptions.length,
              itemBuilder: (context, index) {
                final option = equipmentOptions[index];
                final label = option['label'] as String;
                final image = option['image'] as String?;
                final icon = option['icon'] as IconData?;
                final isSelected = selectedEquipment.contains(label);

                return GridSelectionCard(
                  imageAsset: image,
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  onTap: () => _toggleEquipment(label),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
