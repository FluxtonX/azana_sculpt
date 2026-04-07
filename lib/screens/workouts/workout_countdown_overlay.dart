// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// 3-2-1 GO! animated countdown overlay before a workout starts.
/// Call [WorkoutCountdownOverlay.show] and await it — resolves when countdown finishes.
class WorkoutCountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const WorkoutCountdownOverlay({super.key, required this.onComplete});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => WorkoutCountdownOverlay(
        onComplete: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<WorkoutCountdownOverlay> createState() => _WorkoutCountdownOverlayState();
}

class _WorkoutCountdownOverlayState extends State<WorkoutCountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 3;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 1.4, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInBack),
    );
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _count = i);
      _ctrl.forward(from: 0);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _displayText => _count == 0 ? 'GO! 🔥' : '$_count';

  Color get _countColor {
    if (_count == 0) return AppTheme.accent;
    if (_count == 1) return AppTheme.primary;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, child) => Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Text(
                  _displayText,
                  key: ValueKey(_count),
                  style: TextStyle(
                    fontSize: _count == 0 ? 72 : 120,
                    fontWeight: FontWeight.w900,
                    color: _countColor,
                    fontFamily: 'Outfit',
                    shadows: [
                      Shadow(
                        color: _countColor.withOpacity(0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _count == 0 ? 'Let\'s sculpt! 💪' : 'Get ready...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
