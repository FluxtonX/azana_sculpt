import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/selection_card.dart';

class SupplementsStep extends StatelessWidget {
  final String selectedOption;
  final ValueChanged<String> onOptionChanged;

  const SupplementsStep({
    super.key,
    required this.selectedOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Do you take supplements?",
          subtitle: "This helps us optimize your nutrition plan",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SelectionCard(
                icon: Icons.medication_rounded,
                label: "Yes, I take supplements",
                isSelected: selectedOption == 'yes',
                onTap: () => onOptionChanged('yes'),
              ),
              const SizedBox(height: 16),
              SelectionCard(
                icon: Icons.close_rounded,
                label: "No, I don't",
                isSelected: selectedOption == 'no',
                onTap: () => onOptionChanged('no'),
              ),
              const SizedBox(height: 16),
              SelectionCard(
                icon: Icons.help_outline_rounded,
                label: "Sometimes",
                isSelected: selectedOption == 'sometimes',
                onTap: () => onOptionChanged('sometimes'),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
