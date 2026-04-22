import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/number_selection_card.dart';

class MotivationStep extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;

  const MotivationStep({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Motivation for the new routine?",
          subtitle: "On a scale of 1 to 5, how motivated are you generally to start and stick to a new fitness routine?",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
                final level = index + 1;
                return NumberSelectionCard(
                  number: level,
                  isSelected: selectedLevel == level,
                  onTap: () => onLevelChanged(level),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
