import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A ring gauge with a big percentage and a caption underneath.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.fraction,
    required this.caption,
    this.size = 150,
    this.color = AppTheme.gold,
  });

  final double fraction;
  final String caption;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(fraction.clamp(0.0, 1.0), color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(
                  fontFamilyFallback: AppTheme.serif,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textHigh,
                ),
              ),
              Text(caption,
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.fraction, this.color);
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = const Color(0xFF1B2740),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
