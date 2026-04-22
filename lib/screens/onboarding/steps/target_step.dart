import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';
import '../widgets/grid_selection_card.dart';

class TargetStep extends StatelessWidget {
  final TextEditingController answerController;
  final bool? hasGymAccess;
  final ValueChanged<bool?> onGymAccessChanged;

  const TargetStep({
    super.key,
    required this.answerController,
    required this.hasGymAccess,
    required this.onGymAccessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: "Your after 12-16 weeks?",
            subtitle: "What would your dream body look like in the next 12–16 weeks?",
          ),
          
          // 1. Dream Body Text Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE5E9EF),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: answerController,
                maxLines: null,
                minLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "Your answer",
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFFAAB5C3),
                    fontSize: 16,
                  ),
                  contentPadding: EdgeInsets.all(20),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 2. Gym Access Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Do you have Gym access?",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 3. Binary Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridSelectionCard(
                      icon: Icons.close_rounded,
                      label: "NO",
                      isSelected: hasGymAccess == false,
                      onTap: () => onGymAccessChanged(false),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridSelectionCard(
                      icon: Icons.check_rounded,
                      label: "YES",
                      isSelected: hasGymAccess == true,
                      onTap: () => onGymAccessChanged(true),
                    ),
                  ),
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
