import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/number_selection_card.dart';

class CommitmentStep extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onLevelChanged;

  const CommitmentStep({
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
          title: "Commitment to the goal?",
          subtitle: "On a scale of 1–10, how serious are you about reaching your goals in 2026? (1 being not that serious, 10 being extremely serious!)",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: 10,
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
