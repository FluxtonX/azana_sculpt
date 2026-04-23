import 'package:flutter/material.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/step_header.dart';
import '../widgets/unit_toggle.dart';

class WeightStep extends StatelessWidget {
  final int selectedWeight;
  final String unit;
  final ValueChanged<int> onWeightChanged;
  final ValueChanged<String> onUnitChanged;

  const WeightStep({
    super.key,
    required this.selectedWeight,
    required this.unit,
    required this.onWeightChanged,
    required this.onUnitChanged,
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
              title: "What's your current weight?",
              subtitle: "We'll use this to calculate your fitness metrics",
            ),
            const SizedBox(height: 10),
            Center(
              child: UnitToggle(
                value: unit,
                options: const ['kg', 'lbs'],
                onChanged: onUnitChanged,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: RulerPicker(
                min: unit == 'kg' ? 30 : 70,
                max: unit == 'kg' ? 200 : 450,
                initialValue: selectedWeight,
                unit: unit,
                style: RulerPickerStyle.traditional,
                onChanged: onWeightChanged,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
