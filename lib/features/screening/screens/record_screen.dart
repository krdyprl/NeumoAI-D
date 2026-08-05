import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_card.dart';
import '../../../core/widgets/neumo_progress.dart';
import '../../../core/widgets/neumo_top_bar.dart';
import '../../../models/enums.dart';
import '../../../models/screening.dart';
import '../../../state/app_providers.dart';
import '../widgets/waveform.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

enum _RecState { idle, recording, done }

class _RecordScreenState extends ConsumerState<RecordScreen> {
  _RecState _state = _RecState.idle;
  int _seconds = 0;
  double _noise = 0.12;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _state = _RecState.recording;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds++;
        _noise = 0.08 + (DateTime.now().millisecondsSinceEpoch % 20) / 100;
        if (_seconds >= 5) {
          t.cancel();
          _state = _RecState.done;
        }
      });
    });
  }

  void _retry() {
    _timer?.cancel();
    setState(() {
      _state = _RecState.idle;
      _seconds = 0;
    });
  }

  Future<void> _submit() async {
    final id = 's${DateTime.now().millisecondsSinceEpoch}';
    // mock: always pending high risk for demo
    final risk = RiskLevel.high;
    final confidence = 87;
    final screening = Screening(
      id: id,
      childId: ref.read(currentChildIdProvider).valueOrNull ?? 'c1',
      date: DateTime.now().toIso8601String(),
      symptoms: const ['batuk', 'demam'],
      audioDuration: 5,
      riskLevel: risk,
      disease: 'Pneumonia',
      confidence: confidence,
      status: SyncStatus.pending,
    );
    await ref.read(screeningsProvider.notifier).add(screening);
    ref.read(syncQueueProvider).enqueue(SyncItem(
          id: id,
          type: 'screening',
          payload: {'id': id, 'childId': screening.childId, 'confidence': confidence},
          createdAt: DateTime.now(),
        ));
    if (mounted) context.go('/processing');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final progress = (_seconds / 5 * 100).clamp(0, 100).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Rekam Suara Batuk'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                const Text('Rekam batuk si kecil selama 5 detik',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                const SizedBox(height: 4),
                const Text('Posisikan ponsel 15–20 cm dari mulut si kecil.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                const SizedBox(height: 20),
                NeumoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _state == _RecState.recording ? AppColors.danger : AppColors.lightFaint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_state == _RecState.recording
                                ? 'Sedang merekam…'
                                : _state == _RecState.done
                                    ? 'Rekaman selesai'
                                    : 'Siap merekam',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightMuted)),
                        const Spacer(),
                        Text('0:0${_seconds.clamp(0, 5)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ink)),
                      ]),
                      const SizedBox(height: 20),
                      Waveform(
                        active: _state == _RecState.recording,
                        color: _state == _RecState.done ? AppColors.secondary : AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      NeumoProgress(value: progress, color: AppColors.primary),
                    ]),
                  ),
                ),
                if (_state == _RecState.recording) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _noise > 0.22 ? AppColors.lightAccentSoft : AppColors.lightSecondarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Text(_noise > 0.22 ? 'Lingkungan berisik' : 'Kualitas audio baik',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _noise > 0.22 ? AppColors.accentDeep : AppColors.secondaryDeep)),
                    ]),
                  ),
                ],
                const SizedBox(height: 32),
                Center(
                  child: _state == _RecState.done
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh, color: AppColors.danger),
                            tooltip: 'Ulangi',
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                                boxShadow: const [BoxShadow(color: Color(0x803ECF8E), blurRadius: 30)],
                              ),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.check, color: Colors.white, size: 32),
                                Text('Kirim', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ),
                        ])
                      : GestureDetector(
                          onTap: _state == _RecState.recording ? _retry : _start,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _state == _RecState.recording ? AppColors.danger : AppColors.primary,
                              boxShadow: [BoxShadow(color: (_state == _RecState.recording ? AppColors.danger : AppColors.primary).withValues(alpha: 0.5), blurRadius: 30)],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_state == _RecState.recording ? Icons.stop : Icons.mic,
                                    color: Colors.white, size: 36),
                                if (_state == _RecState.idle) ...[
                                  const SizedBox(height: 2),
                                  Text('Rekam',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                if (_state == _RecState.done)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.lightSecondarySoft, borderRadius: BorderRadius.circular(16)),
                    child: const Text('✅ Rekaman tersimpan secara lokal. Akan diunggah otomatis saat AI mulai menganalisis.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.secondaryDeep)),
                  )
                else
                  Center(
                    child: TextButton(
                      onPressed: _submit,
                      child: const Text('Unggah rekaman audio', style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
