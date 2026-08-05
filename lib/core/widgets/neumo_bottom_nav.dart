import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeumoBottomNav extends StatelessWidget {
  const NeumoBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<(IconData, String)> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = dark ? AppColors.darkSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.72);
    final faint = dark ? AppColors.darkFaint : AppColors.lightFaint;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? AppColors.darkBorder : Colors.white),
        boxShadow: const [BoxShadow(color: Color(0x1A0B1B33), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tabs[i].$1, size: 22,
                          color: i == currentIndex ? AppColors.primary : faint),
                      const SizedBox(height: 2),
                      Text(tabs[i].$2,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: i == currentIndex ? AppColors.primary : faint)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
