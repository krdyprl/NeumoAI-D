import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoProgress extends StatelessWidget {
  const NeumoProgress({super.key, required this.value, this.color = AppColors.primary, this.height = 10});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: (value / 100).clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: dark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
