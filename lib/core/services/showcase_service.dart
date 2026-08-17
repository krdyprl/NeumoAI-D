import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../data/repositories/settings_repository.dart';

/// Callbacks wired from the global tour.
typedef OnShowcaseStepComplete = void Function(int index, GlobalKey key);
typedef OnShowcaseSkip = void Function();

class ShowcaseService {
  ShowcaseService(this._settings);

  final SettingsRepository _settings;

  Future<bool> isDone(String screen) => _settings.isShowcaseDone(screen);

  Future<void> markDone(String screen) => _settings.markShowcaseDone(screen);

  Future<bool> shouldShow(String screen) async => !(await _settings.isShowcaseDone(screen));

  Future<void> resetShowcase(String screen) => _settings.resetShowcase(screen);

  void startShowCase(List<GlobalKey> keys) {
    if (keys.isEmpty) return;
    ShowcaseView.get().startShowCase(keys);
  }

  /// Registers the global ShowcaseView with Neumo-styled "Lanjut" and "Lewati"
  /// actions. [onStepComplete] fires when a step finishes (used by the tour to
  /// move to the next route), [onSkip] fires when the user taps "Lewati".
  void registerGlobal({
    OnShowcaseStepComplete? onStepComplete,
    OnShowcaseSkip? onSkip,
  }) {
    ShowcaseView.register(
      globalTooltipActions: [
        TooltipActionButton.custom(
          button: _SkipButton(onTap: onSkip),
        ),
        TooltipActionButton.custom(
          button: _NextButton(onTap: () => ShowcaseView.get().next()),
        ),
      ],
      globalTooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        position: TooltipActionPosition.outside,
        actionGap: 10,
        gapBetweenContentAndAction: 14,
      ),
      blurValue: 3,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 350),
      onComplete: (index, key) => onStepComplete?.call(index ?? 0, key),
    );
  }
}

/// Neumo-styled primary "Lanjut" button.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D7AFC), Color(0xFF1564D4)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Color(0x401D7AFC), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lanjut',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Neumo-styled "Lewati" button.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'Lewati',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
