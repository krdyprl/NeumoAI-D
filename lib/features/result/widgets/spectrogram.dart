import 'dart:math' as math;

import 'package:flutter/material.dart';

class Spectrogram extends StatelessWidget {
  const Spectrogram({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(double.infinity, 92), painter: _SpectrogramPainter());
  }
}

class _SpectrogramPainter extends CustomPainter {
  final math.Random _random = math.Random(7);

  static const Color _blue = Color(0xFF1D7AFC);
  static const Color _green = Color(0xFF3ECF8E);
  static const Color _orange = Color(0xFFFF8A00);
  static const Color _red = Color(0xFFEF4444);

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 14;
    const cols = 40;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final v = _random.nextDouble();
        final freq = r < 3 ? 0.15 : r < 7 ? 0.3 : r < 11 ? 0.5 : 0.75;
        final heat = (v * freq * ((c > 18 && c < 30) ? 1.3 : 1.0)).clamp(0.0, 1.0);
        final color = heat < 0.25
            ? _blue.withValues(alpha: 0.08 + heat * 0.2)
            : heat < 0.55
                ? _green.withValues(alpha: heat * 0.7)
                : heat < 0.8
                    ? _orange.withValues(alpha: heat * 0.8)
                    : _red.withValues(alpha: heat);
        canvas.drawRect(
          Rect.fromLTWH(c * cellW + 0.5, r * cellH + 0.5, cellW - 1, cellH - 1),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
