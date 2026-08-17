import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../theme/app_colors.dart';

class NeumoShowcase extends StatelessWidget {
  const NeumoShowcase({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.shapeBorder,
    this.targetPadding,
  }) : assert(key is GlobalKey<State<StatefulWidget>>,
         'NeumoShowcase requires a GlobalKey<State<StatefulWidget>> as its key');

  final String title;
  final String description;
  final Widget child;
  final ShapeBorder? shapeBorder;
  final EdgeInsets? targetPadding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;

    return Showcase(
      key: key as GlobalKey<State<StatefulWidget>>,
      title: title,
      description: description,
      targetPadding: targetPadding ?? const EdgeInsets.all(4),
      targetShapeBorder: shapeBorder ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary, width: 3),
      ),
      overlayColor: Colors.black,
      overlayOpacity: 0.72,
      blurValue: 3,
      tooltipBackgroundColor: surface,
      tooltipBorderRadius: BorderRadius.circular(18),
      tooltipPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      targetTooltipGap: 14,
      textColor: ink,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      descTextStyle: TextStyle(
        fontSize: 13,
        height: 1.5,
        color: muted,
      ),
      titlePadding: const EdgeInsets.only(bottom: 6),
      showArrow: true,
      child: child,
    );
  }
}
