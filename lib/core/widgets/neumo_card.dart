import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoCard extends StatelessWidget {
  const NeumoCard({super.key, this.onTap, this.interactive = false, required this.child});

  final VoidCallback? onTap;
  final bool interactive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border.all(color: dark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0B1B33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null && !interactive) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: content,
    );
  }
}
