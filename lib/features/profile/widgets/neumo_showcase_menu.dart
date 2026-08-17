import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../core/services/tour_controller.dart';

/// Menu bantuan yang menampilkan status tour global dan menyediakan tombol
/// untuk menampilkan ulang tour panduan fitur.
class NeumoShowcaseMenu extends ConsumerStatefulWidget {
  const NeumoShowcaseMenu({super.key, this.onTapShowAll});

  final VoidCallback? onTapShowAll;

  @override
  ConsumerState<NeumoShowcaseMenu> createState() => _NeumoShowcaseMenuState();
}

class _NeumoShowcaseMenuState extends ConsumerState<NeumoShowcaseMenu> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.onTapShowAll != null) ...[
        NeumoButton(
          size: NeumoSize.md,
          label: 'Mulai Tour Panduan',
          icon: Icons.play_circle_fill,
          onPressed: widget.onTapShowAll,
        ),
        const SizedBox(height: 16),
      ],
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.help_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tour panduan menjelaskan setiap fitur aplikasi secara berurutan dari Beranda hingga Profil.',
              style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      NeumoButton(
        size: NeumoSize.md,
        variant: NeumoVariant.outline,
        label: 'Reset & Tampilkan Lagi',
        icon: Icons.refresh,
        onPressed: _resetAndRun,
      ),
    ]);
  }

  Future<void> _resetAndRun() async {
    final tour = ref.read(tourControllerProvider.notifier);
    await tour.reset();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tour panduan direset. Buka Beranda untuk menampilkan kembali.')),
      );
    }
  }
}
