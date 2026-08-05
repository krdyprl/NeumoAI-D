import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoSegmented<T> extends StatelessWidget {
  const NeumoSegmented({super.key, required this.options, required this.value, required this.onChanged});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final surface2 = dark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == value ? (dark ? AppColors.darkSurface : AppColors.lightSurface) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: v == value
                        ? const [BoxShadow(color: Color(0x1A0B1B33), blurRadius: 8, offset: Offset(0, 2))]
                        : null,
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: v == value ? AppColors.primary : muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
