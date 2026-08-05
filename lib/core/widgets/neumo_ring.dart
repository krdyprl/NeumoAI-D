import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoRing extends StatelessWidget {
  const NeumoRing({
    super.key,
    required this.value,
    this.size = 88,
    this.stroke = 8,
    this.color = AppColors.primary,
    this.label,
    this.sublabel,
  });

  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? label;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final track = dark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            builder: (_, t, __) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: t,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink, height: 1),
                  child: label!,
                ),
              if (sublabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sublabel!, style: TextStyle(fontSize: 10, color: muted)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
