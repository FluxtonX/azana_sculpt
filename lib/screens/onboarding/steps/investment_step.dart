import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class InvestmentStep extends StatelessWidget {
  final bool? isReadyToInvest;
  final ValueChanged<bool?> onInvestChanged;

  const InvestmentStep({
    super.key,
    required this.isReadyToInvest,
    required this.onInvestChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: "A'zana Sculpt",
            subtitle: "", // We'll use a custom body for the long text
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "A'zana Sculpt is a premium coaching experience for women who are ready to fully commit to transforming their body, habits, and lifestyle — not just \"trying\" for a few weeks.\n\n"
                  "This program focuses on structure, discipline, and real results through personalised training, tailored nutrition, direct coach support, and consistent accountability.\n\n"
                  "Investment starts from £500 for your first 16 weeks program. (You must be ready to commit for 12-weeks minimum) ongoing for clients who are ready to stay committed and see long-term results.",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    height: 1.5,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
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
                        label: "Yes — I'm ready to invest at this level now",
                        isSelected: isReadyToInvest == true,
                        onTap: () => onInvestChanged(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GridSelectionCard(
                        icon: Icons.close_rounded,
                        label: "I'm not in a position to invest now",
                        isSelected: isReadyToInvest == false,
                        onTap: () => onInvestChanged(false),
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
