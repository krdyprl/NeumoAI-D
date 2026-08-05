import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NeumoTone { primary, secondary, accent, danger, neutral, warning }

class NeumoChip extends StatelessWidget {
  const NeumoChip({super.key, required this.tone, required this.child});

  final NeumoTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (tone) {
      NeumoTone.primary => (dark ? AppColors.darkPrimarySoft : AppColors.lightPrimarySoft, AppColors.primary),
      NeumoTone.secondary => (dark ? AppColors.darkSecondarySoft : AppColors.lightSecondarySoft, AppColors.secondaryDeep),
      NeumoTone.accent => (dark ? AppColors.darkAccentSoft : AppColors.lightAccentSoft, AppColors.accentDeep),
      NeumoTone.danger => (dark ? AppColors.darkDangerSoft : AppColors.lightDangerSoft, AppColors.dangerDeep),
      NeumoTone.warning => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      NeumoTone.neutral => (dark ? AppColors.darkSurface2 : AppColors.lightSurface2, dark ? AppColors.darkMuted : AppColors.lightMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
        child: child,
      ),
    );
  }
}
