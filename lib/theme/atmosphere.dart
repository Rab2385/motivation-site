import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A painted "misty mountains at dusk" backdrop. Cheap, deterministic, and
/// theme-matched – stands in for the photographic art in the reference.
class AtmosphereBackground extends StatelessWidget {
  const AtmosphereBackground({
    super.key,
    this.seed = 7,
    this.glowAlignment = const Alignment(0.7, -0.4),
  });

  final int seed;
  final Alignment glowAlignment;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AtmospherePainter(seed: seed, glow: glowAlignment),
      isComplex: true,
      willChange: false,
      child: const SizedBox.expand(),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({required this.seed, required this.glow});

  final int seed;
  final Alignment glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141D33), Color(0xFF0A0E18)],
        ).createShader(rect),
    );

    // Warm glow (a distant sun / beacon).
    final glowCenter = glow.withinRect(rect);
    canvas.drawCircle(
      glowCenter,
      size.shortestSide * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.18),
            AppTheme.gold.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: size.shortestSide * 0.9),
        ),
    );

    final random = math.Random(seed);
    for (var i = 0; i < 40; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height * 0.7;
      canvas.drawCircle(
        Offset(dx, dy),
        random.nextDouble() * 1.1 + 0.2,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.4),
      );
    }

    // Layered ridgelines, back (faint) to front (dark).
    final layers = [
      (0.62, const Color(0xFF1C2740), 5.0),
      (0.74, const Color(0xFF141D30), 4.0),
      (0.86, const Color(0xFF0C1220), 3.0),
    ];
    for (final (baseline, color, roughness) in layers) {
      final ridge = math.Random(seed * 31 + (baseline * 100).round());
      final path = Path()..moveTo(0, size.height);
      final y0 = size.height * baseline;
      path.lineTo(0, y0);
      var x = 0.0;
      var y = y0;
      final step = size.width / 14;
      while (x < size.width) {
        x += step;
        y = (y0 + (ridge.nextDouble() - 0.5) * size.height * 0.07 * roughness)
            .clamp(size.height * 0.35, size.height * 0.98);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.glow != glow;
}

/// The compass-rose mark from the logo.
class CompassMark extends StatelessWidget {
  const CompassMark({super.key, this.size = 34, this.color = AppTheme.gold});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CompassPainter(color)),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05;

    canvas.drawCircle(center, radius * 0.94, stroke);

    final fill = Paint()..color = color;
    final faint = Paint()..color = color.withValues(alpha: 0.45);
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      _star(canvas, center, radius * 0.9, radius * 0.16, angle, fill);
    }
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      _star(canvas, center, radius * 0.5, radius * 0.1, angle, faint);
    }
    canvas.drawCircle(center, radius * 0.08, fill);
  }

  void _star(Canvas canvas, Offset center, double long, double wide,
      double angle, Paint paint) {
    final tip = center + Offset(math.cos(angle), math.sin(angle)) * long;
    final left = center +
        Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2)) *
            wide;
    final right = center +
        Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) *
            wide;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => oldDelegate.color != color;
}

/// Gold progress ring with a soft trailing glow, used for the level display.
class GoldRing extends StatelessWidget {
  const GoldRing({
    super.key,
    required this.fraction,
    this.size = 116,
    this.child,
  });

  final double fraction;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoldRingPainter(fraction.clamp(0.0, 1.0)),
        child: Center(child: child),
      ),
    );
  }
}

class _GoldRingPainter extends CustomPainter {
  _GoldRingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF20304C),
    );

    final sweep = 2 * math.pi * fraction;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6
        ..shader = const SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [AppTheme.goldDim, AppTheme.gold, AppTheme.goldBright],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5),
    );
  }

  @override
  bool shouldRepaint(_GoldRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
