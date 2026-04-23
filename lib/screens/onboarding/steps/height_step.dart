import 'package:flutter/material.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/step_header.dart';

class HeightStep extends StatelessWidget {
  final int selectedHeight;
  final String unit;
  final ValueChanged<int> onHeightChanged;

  const HeightStep({
    super.key,
    required this.selectedHeight,
    required this.unit,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepHeader(
              title: "What's your height?",
              subtitle: "Height helps calculate BMI and calorie needs",
            ),
            const SizedBox(height: 60),
            Center(
              child: RulerPicker(
                min: 120,
                max: 230,
                initialValue: selectedHeight,
                unit: unit,
                onChanged: onHeightChanged,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
