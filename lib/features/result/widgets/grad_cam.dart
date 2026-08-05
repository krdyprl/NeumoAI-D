import 'dart:math' as math;

import 'package:flutter/material.dart';

class GradCam extends StatelessWidget {
  const GradCam({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(double.infinity, 140), painter: _GradCamPainter());
  }
}

class _GradCamPainter extends CustomPainter {
  final math.Random _random = math.Random(13);

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 12;
    final cellW = size.width / grid;
    final cellH = size.height / grid;
    for (var i = 0; i < grid; i++) {
      for (var j = 0; j < grid; j++) {
        final dist = math.sqrt(math.pow((i - 6) / 6, 2) + math.pow((j - 6) / 6, 2));
        final band = math.exp(-dist * 2.2) + (i > 7 ? 0.25 : 0);
        final v = (band + _random.nextDouble() * 0.15).clamp(0.0, 1.0);
        final color = const Color(0xFFEF4444).withValues(alpha: v < 0.2 ? 0.15 : v * 0.95);
        canvas.drawRect(
          Rect.fromLTWH(j * cellW + 0.5, i * cellH + 0.5, cellW - 1, cellH - 1),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
