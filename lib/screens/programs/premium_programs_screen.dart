// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../widgets/premium_lock_overlay.dart';

class PremiumProgramsScreen extends StatelessWidget {
  const PremiumProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Elite Access'),
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUpgradeHeroCard(),
            const SizedBox(height: 28),
            const Text(
              'Premium Content',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unlock your full transformation with elite programmes.',
              style: TextStyle(fontSize: 13, color: AppTheme.textLight),
            ),
            const SizedBox(height: 20),
            _buildLockedProgramCard(
              emoji: '🍽️',
              title: '21-Day Meal Plan',
              description: 'Nutrition designed for body recomposition and sustained energy.',
              tag: 'NUTRITION',
              tagColor: const Color(0xFF2EB87D),
            ),
            const SizedBox(height: 16),
            _buildLockedProgramCard(
              emoji: '⚡',
              title: 'Advanced Sculpt Series',
              description: 'High-intensity circuits for women who are ready to level up.',
              tag: 'ADVANCED',
              tagColor: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            _buildLockedProgramCard(
              emoji: '🧘‍♀️',
              title: '30-Day Mind & Body Reset',
              description: 'Mindfulness, mobility, and recovery for the whole you.',
              tag: 'WELLNESS',
              tagColor: const Color(0xFF9B89E8),
            ),
            const SizedBox(height: 16),
            _buildLockedProgramCard(
              emoji: '💎',
              title: '1-on-1 Coaching Access',
              description: 'Weekly check-ins, bespoke feedback, and direct coach messaging.',
              tag: 'COACHING',
              tagColor: AppTheme.accent,
            ),
            const SizedBox(height: 32),
            _buildValuePropositionCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeHeroCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCDA96E), Color(0xFFD4847A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text(
            'Unlock Elite Access',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade for your full transformation — advanced programmes, meal plans, and personal coaching.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start Free Trial',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: AppTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedProgramCard({
    required String emoji,
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
  }) {
    return PremiumLockOverlay(
      lockMessage: 'Upgrade to unlock',
      onUpgradeTap: () {},
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textDark.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: tagColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMedium,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuePropositionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentLight.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why go Elite?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildValuePoint('🎯', 'Programmes tailored to your exact goals'),
          _buildValuePoint('🥗', 'Expert meal plans built for body recomposition'),
          _buildValuePoint('📊', 'Advanced analytics and progress insights'),
          _buildValuePoint('💬', 'Direct access to your personal coach'),
          _buildValuePoint('👑', 'Elite members see 3× better results on average'),
        ],
      ),
    );
  }

  Widget _buildValuePoint(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
