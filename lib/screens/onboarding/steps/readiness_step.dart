import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class ReadinessStep extends StatelessWidget {
  final bool? isReadyToStart;
  final ValueChanged<bool?> onReadinessChanged;

  const ReadinessStep({
    super.key,
    required this.isReadyToStart,
    required this.onReadinessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: "Ready to start?",
            subtitle: "", 
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Please only continue with submission of this form if you are genuinely ready to begin your coaching journey and commit to your transformation.",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    height: 1.5,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                 const Text(
                  "Which best describes you now?",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridSelectionCard(
                        icon: Icons.check_rounded,
                        label: "Yes — I'm ready to get started now",
                        isSelected: isReadyToStart == true,
                        onTap: () => onReadinessChanged(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GridSelectionCard(
                        icon: Icons.close_rounded,
                        label: "No — I'm not ready at this time",
                        isSelected: isReadyToStart == false,
                        onTap: () => onReadinessChanged(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
