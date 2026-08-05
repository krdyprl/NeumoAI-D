import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoNotifBell extends StatelessWidget {
  const NeumoNotifBell({super.key, required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_none, size: 20, color: ink),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 18,
              constraints: const BoxConstraints(minWidth: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(999)),
              child: Text('$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
