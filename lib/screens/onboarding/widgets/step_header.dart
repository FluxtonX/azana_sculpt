import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const StepHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
