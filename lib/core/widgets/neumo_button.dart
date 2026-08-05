import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NeumoVariant { primary, secondary, accent, outline, ghost, danger, soft }

class NeumoButton extends StatelessWidget {
  const NeumoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NeumoVariant.primary,
    this.size = NeumoSize.md,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NeumoVariant variant;
  final NeumoSize size;
  final IconData? icon;
  final bool expand;

  Color _bg(BuildContext c) => switch (variant) {
        NeumoVariant.primary => AppColors.primary,
        NeumoVariant.secondary => AppColors.secondary,
        NeumoVariant.accent => AppColors.accent,
        NeumoVariant.outline => Colors.transparent,
        NeumoVariant.ghost => Colors.transparent,
        NeumoVariant.danger => AppColors.danger,
        NeumoVariant.soft => AppColors.lightPrimarySoft,
      };

  Color _fg(BuildContext c) => switch (variant) {
        NeumoVariant.primary || NeumoVariant.accent || NeumoVariant.danger =>
          Colors.white,
        NeumoVariant.secondary => const Color(0xFF06301F),
        NeumoVariant.outline || NeumoVariant.ghost => AppColors.primary,
        NeumoVariant.soft => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final (double height, double padding, double radius, double fontSize) =
        switch (size) {
      NeumoSize.sm => (36.0, 16.0, 12.0, 13.0),
      NeumoSize.md => (48.0, 24.0, 16.0, 15.0),
      NeumoSize.lg => (56.0, 32.0, 16.0, 16.0),
    };

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: fontSize + 2), const SizedBox(width: 6)],
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
      ],
    );

    if (variant == NeumoVariant.outline || variant == NeumoVariant.ghost) {
      return SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _fg(context),
            backgroundColor: variant == NeumoVariant.ghost ? AppColors.lightPrimarySoft.withValues(alpha: 0.35) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: variant == NeumoVariant.outline ? BorderSide(color: AppColors.lightBorder) : BorderSide.none,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _bg(context),
          foregroundColor: _fg(context),
          padding: EdgeInsets.symmetric(horizontal: padding),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
        child: child,
      ),
    );
  }
}

enum NeumoSize { sm, md, lg }
