// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/badge_model.dart';
import '../../services/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with SingleTickerProviderStateMixin {
  List<BadgeModel> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final badges = await BadgeService().loadBadges();
    if (mounted) setState(() { _badges = badges; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _badges.where((b) => b.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressHeader(unlocked),
                  const SizedBox(height: 28),
                  const Text(
                    'Your Badges',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _badges.length,
                    itemBuilder: (context, i) => _BadgeCard(badge: _badges[i]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressHeader(int unlocked) {
    final total = _badges.length;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked of $total Badges Unlocked',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked == total
                          ? 'You\'ve collected them all! You are an icon. 👑'
                          : 'Keep showing up to unlock more.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatefulWidget {
  final BadgeModel badge;
  const _BadgeCard({required this.badge});

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.badge.isUnlocked;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: unlocked
              ? Border.all(
                  color: AppTheme.accent.withOpacity(0.35),
                  width: 1.5,
                )
              : Border.all(color: AppTheme.divider, width: 1),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.textDark.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppTheme.accentLight.withOpacity(0.2)
                        : AppTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: unlocked
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                          : const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 0.4, 0,
                            ]),
                      child: Text(
                        widget.badge.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),
                if (!unlocked)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                if (unlocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                widget.badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? AppTheme.textDark : AppTheme.textLight,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
