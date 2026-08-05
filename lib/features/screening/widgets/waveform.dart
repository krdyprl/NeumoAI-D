import 'dart:math' as math;

import 'package:flutter/material.dart';

class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    this.active = true,
    this.barCount = 42,
    this.color = const Color(0xFF1D7AFC),
    this.height = 96,
  });

  final bool active;
  final int barCount;
  final Color color;
  final double height;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _WaveformPainter(
            seed: widget.active ? _random.nextDouble() : 0.5,
            color: widget.color,
            barCount: widget.barCount,
            active: widget.active,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.seed,
    required this.color,
    required this.barCount,
    required this.active,
  });

  final double seed;
  final Color color;
  final int barCount;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = 3.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < barCount; i++) {
      final v = active ? (0.15 + (seed * 1000 + i * 7) % 85 / 100) : 0.35;
      final h = math.max(8.0, v * size.height);
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, barWidth, h),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
