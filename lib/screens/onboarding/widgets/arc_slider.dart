import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../constants/app_theme.dart';

class ArcSlider extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

  const ArcSlider({
    super.key,
    this.min = 1,
    this.max = 5,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ArcSlider> createState() => _ArcSliderState();
}

class _ArcSliderState extends State<ArcSlider> {
  late int _currentValue;

  // Arc geometry
  static const double _startAngle = 210 * math.pi / 180; // bottom-left
  static const double _endAngle = -30 * math.pi / 180; // top-right
  static const double _sweepAngle = _endAngle - _startAngle + 2 * math.pi;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(ArcSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  int _angleToValue(double angle) {
    // Normalize angle
    double normalizedAngle = angle;
    while (normalizedAngle < _startAngle - math.pi) {
      normalizedAngle += 2 * math.pi;
    }
    while (normalizedAngle > _startAngle + math.pi) {
      normalizedAngle -= 2 * math.pi;
    }

    final fraction = (normalizedAngle - _startAngle) / _sweepAngle;
    final value = widget.min + (fraction * (widget.max - widget.min)).round();
    return value.clamp(widget.min, widget.max);
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    Offset center,
    double radius,
  ) {
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final angle = math.atan2(dy, dx);

    final newValue = _angleToValue(angle);
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 380;
    const double radius = 180;
    const Offset center = Offset(size / 2, size / 2);

    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanUpdate: (details) => _handlePanUpdate(details, center, radius),
        onTapDown: (details) {
          final dx = details.localPosition.dx - center.dx;
          final dy = details.localPosition.dy - center.dy;
          final angle = math.atan2(dy, dx);
          final newValue = _angleToValue(angle);
          if (newValue != _currentValue) {
            setState(() {
              _currentValue = newValue;
            });
            widget.onChanged(_currentValue);
          }
        },
        child: CustomPaint(
          size: const Size(size, size),
          painter: _ArcPainter(
            min: widget.min,
            max: widget.max,
            value: _currentValue,
            primaryColor: AppTheme.primary,
            trackColor: const Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final int min;
  final int max;
  final int value;
  final Color primaryColor;
  final Color trackColor;

  _ArcPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.primaryColor,
    required this.trackColor,
  });

  static const double _startAngle = 210 * math.pi / 180;
  static const double _endAngle = -30 * math.pi / 180;
  static const double _totalSweep = _endAngle - _startAngle + 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double radius = 165;
    const double strokeWidth = 7;

    final fraction = (value - min) / (max - min);
    final valueAngle = _startAngle + fraction * _totalSweep;

    // 1. Draw inactive track (dark)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      valueAngle,
      _totalSweep - fraction * _totalSweep,
      false,
      trackPaint,
    );

    // 2. Draw active track (primary)
    final activePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      fraction * _totalSweep,
      false,
      activePaint,
    );

    // 3. Draw tick marks
    final tickPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final totalTicks = max - min;
    for (int i = 0; i <= totalTicks; i++) {
      final tickFraction = i / totalTicks;
      final tickAngle = _startAngle + tickFraction * _totalSweep;
      final innerRadius = radius - 12;
      final outerRadius = radius + 12;

      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(tickAngle),
        center.dy + innerRadius * math.sin(tickAngle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(tickAngle),
        center.dy + outerRadius * math.sin(tickAngle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // 4. Draw thumb
    final thumbX = center.dx + radius * math.cos(valueAngle);
    final thumbY = center.dy + radius * math.sin(valueAngle);
    final thumbCenter = Offset(thumbX, thumbY);

    // Thumb shadow
    final shadowPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: thumbCenter, width: 52, height: 52),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    // Thumb body
    final thumbPaint = Paint()..color = primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: thumbCenter, width: 46, height: 46),
        const Radius.circular(14),
      ),
      thumbPaint,
    );

    // Thumb icon (refresh/circular arrow)
    final iconPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double iconRadius = 10;
    canvas.drawArc(
      Rect.fromCircle(center: thumbCenter, radius: iconRadius),
      0,
      math.pi * 1.5,
      false,
      iconPaint,
    );

    // Arrow head
    final arrowEnd = Offset(thumbCenter.dx + iconRadius, thumbCenter.dy);
    final arrowPath = Path()
      ..moveTo(arrowEnd.dx - 4, arrowEnd.dy - 5)
      ..lineTo(arrowEnd.dx, arrowEnd.dy)
      ..lineTo(arrowEnd.dx + 4, arrowEnd.dy - 5);
    canvas.drawPath(arrowPath, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
