import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';
import '../widgets/step_header.dart';

class SocialStep extends StatelessWidget {
  final TextEditingController socialController;

  const SocialStep({
    super.key,
    required this.socialController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: "Social media sharing",
          subtitle: "", // Using custom rich text below
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "Share your "),
                    const TextSpan(
                      text: "FULL",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const TextSpan(text: " Instagram or Facebook handle below.\n\n"),
                    const TextSpan(
                      text: "If your application is successful, I'll be in touch using the number you've provided, 💞 ",
                    ),
                    const TextSpan(
                      text: "so please double-check your details.",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
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
                  controller: socialController,
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
            ],
          ),
        ),
      ],
    );
  }
}
