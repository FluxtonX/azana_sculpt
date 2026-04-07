// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Lightweight social proof strip showing community activity.
class CommunityProofStrip extends StatefulWidget {
  const CommunityProofStrip({super.key});

  @override
  State<CommunityProofStrip> createState() => _CommunityProofStripState();
}

class _CommunityProofStripState extends State<CommunityProofStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  int _currentIndex = 0;

  static const List<_ProofItem> _items = [
    _ProofItem(icon: '💪', text: '247 women trained today'),
    _ProofItem(icon: '🏆', text: 'Top workout: Upper Body Sculpt'),
    _ProofItem(icon: '🔥', text: 'Trending: 30-Day Reset'),
    _ProofItem(icon: '⭐', text: 'New achievement unlocked by 12 members'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Rotate every 4 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      await _controller.reverse();
      if (!mounted) return false;
      setState(() => _currentIndex = (_currentIndex + 1) % _items.length);
      _controller.forward();
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              item.text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofItem {
  final String icon;
  final String text;
  const _ProofItem({required this.icon, required this.text});
}
