import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';

class SourceStep extends StatelessWidget {
  final TextEditingController sourceController;

  const SourceStep({
    super.key,
    required this.sourceController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "How did you get in touch?",
          subtitle: "How did you hear about this fitness program?",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E9EF),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: sourceController,
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
      ],
    );
  }
}
