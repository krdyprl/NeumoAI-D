import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.data, this.labels, this.color = const Color(0xFF1D7AFC), this.height = 100});

  final List<double> data;
  final List<String>? labels;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final max = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: (data[i] / max) * 0.88,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.35 + (data[i] / max) * 0.65),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    if (labels != null) ...[
                      const SizedBox(height: 4),
                      Text(labels![i], style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}