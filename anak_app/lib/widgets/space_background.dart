import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Deep-space gradient with a fixed starfield, drawn in code so it scales to
/// any screen without a background image.
class SpaceBackground extends StatelessWidget {
  final int starCount;

  const SpaceBackground({super.key, this.starCount = 90});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1026), Color(0xFF2B1055), Color(0xFF4C1D95)],
        ),
      ),
      child: CustomPaint(
        painter: _StarfieldPainter(starCount),
        size: Size.infinite,
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final int count;

  _StarfieldPainter(this.count);

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed so stars don't jump around on rebuild.
    final rnd = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      paint.color = Colors.white.withValues(
        alpha: 0.35 + rnd.nextDouble() * 0.6,
      );
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
    // A couple of soft nebula glows for depth.
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    glow.color = const Color(0xFF7C3AED).withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      size.shortestSide * 0.35,
      glow,
    );
    glow.color = const Color(0xFF0EA5E9).withValues(alpha: 0.22);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.75),
      size.shortestSide * 0.3,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.count != count;
}
