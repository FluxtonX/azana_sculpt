import 'dart:math' as math;
import 'package:azana_sculpt/constants/app_theme.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Drop-in replacement for _buildFitnessScoreCard()
//  Uses a single AnimationController so the number,
//  arc, and glow dot are always in perfect sync.
// ─────────────────────────────────────────────

class FitnessScoreCard extends StatefulWidget {
  final double score; // 0–100
  final double targetScore; // animated end value
  const FitnessScoreCard({super.key, this.score = 0, this.targetScore = 78});

  @override
  State<FitnessScoreCard> createState() => _FitnessScoreCardState();
}

class _FitnessScoreCardState extends State<FitnessScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);
    // Small delay so the card is visible before animating
    Future.delayed(const Duration(milliseconds: 400), () {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final value = _anim.value * widget.targetScore;
            return _buildCard(value, constraints.maxWidth);
          },
        );
      },
    );
  }

  Widget _buildCard(double value, double maxWidth) {
    // Calculate a scale factor based on standard mobile width (375)
    final double scale = (maxWidth / 375).clamp(0.8, 1.2);
    final double gaugeSize =
        140 * scale; // Slightly smaller gauge to ensure fit

    return Container(
      width: maxWidth,
      height: 300 * scale, // Increased height to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Background image ──
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: 0.9,
                      child: Image.asset(
                        'assets/home/firstCard.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Foreground content ──
          Padding(
            padding: EdgeInsets.all(20.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Fitness Score',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    _TrendBadge(scale: scale),
                  ],
                ),

                SizedBox(height: 6 * scale),

                // Big animated number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 54 * scale,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                        letterSpacing: -1.5,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB0B8C4),
                      ),
                    ),
                  ],
                ),

                // Proportional gap
                SizedBox(height: 12 * scale),

                // Decagon + arc ring + center number
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: gaugeSize,
                    height: gaugeSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(gaugeSize, gaugeSize),
                          painter: _DecagonPainter(color: AppTheme.primary),
                        ),
                        CustomPaint(
                          size: Size(gaugeSize * 0.88, gaugeSize * 0.88),
                          painter: _ArcProgressPainter(
                            progress: value / 100,
                            trackColor: Colors.white.withOpacity(0.22),
                            progressColor: Colors.white,
                            strokeWidth: 9.0 * scale,
                          ),
                        ),
                        Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 42 * scale,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Footer label
                Text(
                  'Based on workouts, consistency & goals',
                  style: TextStyle(
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  +5% Trend badge widget
// ─────────────────────────────────────────────
class _TrendBadge extends StatelessWidget {
  final double scale;
  const _TrendBadge({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F5E9),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 13 * scale,
            color: const Color(0xFF2E8B57),
          ),
          SizedBox(width: 3 * scale),
          Text(
            '+5%',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E8B57),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  10-sided polygon (decagon) painter
// ─────────────────────────────────────────────
class _DecagonPainter extends CustomPainter {
  final Color color;
  const _DecagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    const sides = 10;

    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi * i / sides) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);

    // Subtle inner rim
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DecagonPainter old) => old.color != color;
}

// ─────────────────────────────────────────────
//  Arc progress ring painter
//  Draws a 270° open arc (−135° → +135°) with:
//    • a faint background track
//    • an animated foreground arc
//    • a glowing dot at the arc tip
// ─────────────────────────────────────────────
class _ArcProgressPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _ArcProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  static const double _startDeg =
      -225.0; // top-left gap start  (-135° in standard coords = -225° in Flutter's drawArc which starts at 3 o'clock)
  static const double _sweepDeg = 270.0;

  // Convert degrees to radians helper
  double _rad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Ring radius — slightly inside the decagon
    final r = size.width / 2 - strokeWidth / 2 - 10;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background track
    canvas.drawArc(rect, _rad(_startDeg), _rad(_sweepDeg), false, trackPaint);

    // Foreground progress arc
    final sweepProgress = _sweepDeg * progress;
    if (sweepProgress > 0) {
      canvas.drawArc(
        rect,
        _rad(_startDeg),
        _rad(sweepProgress),
        false,
        progressPaint,
      );
    }

    // Glowing dot at the arc tip
    if (progress > 0.01) {
      final tipAngle = _rad(_startDeg) + _rad(sweepProgress);
      final dotX = cx + r * math.cos(tipAngle);
      final dotY = cy + r * math.sin(tipAngle);

      // Outer glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 + 3,
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Solid dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 + 1,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcProgressPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────
//  Usage — drop this anywhere in your widget tree:
//
//   _buildFitnessScoreCard()   ← returns the card
//
//  Or just use FitnessScoreCard() directly.
// ─────────────────────────────────────────────
Widget buildFitnessScoreCard() => const FitnessScoreCard(targetScore: 78);
