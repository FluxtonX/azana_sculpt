import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class SleepStep extends StatelessWidget {
  final String selectedSleep;
  final ValueChanged<String> onSleepChanged;

  const SleepStep({
    super.key,
    required this.selectedSleep,
    required this.onSleepChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sleepOptions = [
      {
        'label': 'Poor',
        'subtitle': '< 5 hours',
        'icon': Icons.sentiment_very_dissatisfied_rounded
      },
      {
        'label': 'Fair',
        'subtitle': '5–6 hours',
        'icon': Icons.sentiment_neutral_rounded
      },
      {
        'label': 'Good',
        'subtitle': '6–7 hours',
        'icon': Icons.sentiment_satisfied_rounded
      },
      {
        'label': 'Excellent',
        'subtitle': '8+ hours',
        'icon': Icons.sentiment_very_satisfied_rounded
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Sleep quality?",
          subtitle: "Sleep is crucial for recovery and performance",
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: sleepOptions.length,
              itemBuilder: (context, index) {
                final option = sleepOptions[index];
                final label = option['label'] as String;
                final subtitle = option['subtitle'] as String;
                final icon = option['icon'] as IconData;
                final isSelected = selectedSleep == label;

                return GridSelectionCard(
                  icon: icon,
                  label: label,
                  subtitle: subtitle,
                  isSelected: isSelected,
                  onTap: () => onSleepChanged(label),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
