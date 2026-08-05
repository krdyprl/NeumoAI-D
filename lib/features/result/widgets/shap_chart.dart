import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SHAPChart extends StatelessWidget {
  const SHAPChart({super.key, required this.data});

  final List<(String, double)> data;

  @override
  Widget build(BuildContext context) {
    final maxAbs = data.fold<double>(0.01, (m, d) => math.max(m, d.$2.abs()));
    return Column(
      children: [
        for (final (label, value) in data) ...[
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.lightInk))),
            Text(value >= 0 ? '+${value.toStringAsFixed(2)}' : value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightMuted)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value.abs() / maxAbs).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.lightSurface2,
              valueColor: AlwaysStoppedAnimation(value >= 0 ? AppColors.danger : AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
