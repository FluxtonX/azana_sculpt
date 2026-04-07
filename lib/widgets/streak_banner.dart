// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Animated streak banner — shows flame tier, streak count, and at-risk warning.
class StreakBanner extends StatefulWidget {
  final int streakCount;
  final bool isAtRisk;

  const StreakBanner({
    super.key,
    required this.streakCount,
    this.isAtRisk = false,
  });

  @override
  State<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<StreakBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _streakEmoji {
    if (widget.streakCount >= 30) return '👑';
    if (widget.streakCount >= 14) return '⚡';
    if (widget.streakCount >= 7) return '🔥';
    if (widget.streakCount >= 3) return '✨';
    return '💪';
  }

  String get _streakLabel {
    if (widget.streakCount == 0) return 'Start your streak!';
    if (widget.streakCount == 1) return '1 Day Streak';
    return '${widget.streakCount} Day Streak';
  }

  Color get _accentColor {
    if (widget.isAtRisk) return const Color(0xFFE8714A);
    if (widget.streakCount >= 30) return AppTheme.accent;
    if (widget.streakCount >= 7) return AppTheme.primary;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isAtRisk
        ? const Color(0xFFFFF0EC)
        : AppTheme.primaryLight.withOpacity(0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated emoji
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _streakEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _streakLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.isAtRisk
                      ? "Don't break your streak — train today! 🔥"
                      : _streakSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Glow indicator for at-risk
          if (widget.isAtRisk)
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, _unused) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8714A).withOpacity(_glowAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8714A)
                          .withOpacity(_glowAnim.value * 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _streakSubtitle {
    if (widget.streakCount >= 30) return 'You are an absolute icon. Keep going! 👑';
    if (widget.streakCount >= 14) return 'Two weeks strong. Nothing can stop you. ⚡';
    if (widget.streakCount >= 7) return 'One full week. You are on fire! 🔥';
    if (widget.streakCount >= 3) return 'The habit is forming. Keep showing up!';
    return 'Show up today. Your future self will thank you.';
  }
}
