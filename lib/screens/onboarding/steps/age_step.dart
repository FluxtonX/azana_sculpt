import 'package:flutter/material.dart';
import '../widgets/vertical_number_picker.dart';
import '../widgets/step_header.dart';

class AgeStep extends StatelessWidget {
  final int selectedAge;
  final ValueChanged<int> onAgeChanged;

  const AgeStep({
    super.key,
    required this.selectedAge,
    required this.onAgeChanged,
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
              title: "How old are you?",
              subtitle: "Age helps us tailor the intensity of your workouts",
            ),
            const SizedBox(height: 60),
            Center(
              child: VerticalNumberPicker(
                min: 10,
                max: 100,
                initialValue: selectedAge,
                onChanged: onAgeChanged,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
