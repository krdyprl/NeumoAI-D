import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoEmptyState extends StatelessWidget {
  const NeumoEmptyState({super.key, required this.icon, required this.title, required this.desc, this.action});

  final String icon;
  final String title;
  final String desc;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: muted)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
