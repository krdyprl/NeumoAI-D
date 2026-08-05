import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoSyncStatus extends StatelessWidget {
  const NeumoSyncStatus({super.key, required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    final synced = pending == 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = synced
        ? (dark ? AppColors.darkSecondarySoft : AppColors.lightSecondarySoft)
        : (dark ? AppColors.darkAccentSoft : AppColors.lightAccentSoft);
    final fg = synced ? AppColors.secondaryDeep : AppColors.accentDeep;
    final dot = synced ? AppColors.secondary : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(synced ? 'Tersinkronisasi' : 'Menyinkronkan ($pending)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
