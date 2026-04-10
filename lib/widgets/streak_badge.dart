import 'package:flutter/material.dart';
import '../models/achievement_models.dart';

class StreakBadge extends StatelessWidget {
  final AchievementMilestone milestone;

  const StreakBadge({
    super.key,
    required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badge Image with Circular Background and Shadow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Image.asset(
            milestone.assetPath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        
        // Milestone Title Text
        Text(
          milestone.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
