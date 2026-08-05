import 'dart:math' as math;

import 'package:flutter/material.dart';

class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.data, this.color = const Color(0xFF1D7AFC), this.unit, this.height = 120});

  final List<double> data;
  final Color color;
  final String? unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (unit != null)
        Align(
          alignment: Alignment.topRight,
          child: Text(unit!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        ),
      SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _LineChartPainter(data: data, color: color)),
      ),
    ]);
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(math.min) * 0.95;
    final maxV = data.reduce(math.max) * 1.05;
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    Offset point(int i) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * (size.height - 16) - 8;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final p = point(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final last = point(data.length - 1);
    canvas.drawCircle(last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}