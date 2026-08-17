import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const NeumoTopBar({super.key, required this.title, this.onBack, this.right, this.transparent = false});

  final String title;
  final VoidCallback? onBack;
  final Widget? right;
  final bool transparent;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: transparent ? Colors.transparent : bg.withValues(alpha: 0.85),
      child: Row(
        children: [
          if (onBack != null || Navigator.of(context).canPop()) ...[
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surface,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: null),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink)),
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}
