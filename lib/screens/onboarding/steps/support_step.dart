import 'package:flutter/material.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class SupportStep extends StatelessWidget {
  final String selectedSupport;
  final ValueChanged<String> onSupportChanged;

  const SupportStep({
    super.key,
    required this.selectedSupport,
    required this.onSupportChanged,
  });

  @override
  Widget build(BuildContext context) {
    final supportOptions = [
      {'label': 'Not Sure', 'icon': Icons.help_outline_rounded},
      {'label': 'Full Support', 'icon': Icons.handshake_rounded},
      {'label': 'Other', 'icon': Icons.more_horiz_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Support needed or looking for?",
          subtitle: "What kind of support are you looking for in your fitness journey?",
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
              itemCount: supportOptions.length,
              itemBuilder: (context, index) {
                final option = supportOptions[index];
                final label = option['label'] as String;
                final icon = option['icon'] as IconData;
                final isSelected = selectedSupport == label;

                return GridSelectionCard(
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  onTap: () => onSupportChanged(label),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
