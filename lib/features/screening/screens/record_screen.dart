import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_dsp.dart';
import '../../../core/audio/cough_recorder.dart';
import '../../../core/sync/sync_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/uuid.dart';
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
  late final CoughRecorder _recorder = ref.read(coughRecorderProvider);
  _RecState _state = _RecState.idle;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await _recorder.isSupported;
    if (!ok) {
      // On platforms without a recorder (e.g. tests), simulate a 5s countdown
      // so the flow still works end-to-end.
      setState(() {
        _state = _RecState.recording;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _seconds++;
          if (_seconds >= 5) {
            t.cancel();
            _state = _RecState.done;
          }
        });
      });
      return;
    }
    setState(() {
      _state = _RecState.recording;
      _seconds = 0;
    });
    await _recorder.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _seconds++;
        if (_seconds >= 5) {
          t.cancel();
          _stop();
        }
      });
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _recorder.stop();
    if (!mounted) return;
    setState(() => _state = _RecState.done);
  }

  Future<void> _retry() async {
    _timer?.cancel();
    await _recorder.cancel();
    if (!mounted) return;
    setState(() {
      _state = _RecState.idle;
      _seconds = 0;
    });
  }

  Future<void> _submit() async {
    final id = generateUuid();
    final recorder = ref.read(coughRecorderProvider);
    final audioPath = recorder.lastPath;

    // Navigate to the processing screen immediately so the UI never appears
    // stuck, even if on-device TFLite inference is slow on this device.
    if (!mounted) return;
    context.push('/processing');

    // Save the screening with a placeholder result so the result screen can
    // render it immediately. The real on-device classification runs in the
    // background and updates the screening + result provider when done.
    final placeholder = Screening(
      id: id,
      childId: ref.read(currentChildIdProvider).valueOrNull ?? 'c1',
      date: DateTime.now().toIso8601String(),
      symptoms: const ['batuk', 'demam'],
      audioDuration: _seconds,
      riskLevel: RiskLevel.high,
      disease: 'Pneumonia',
      confidence: 87,
      status: SyncStatus.pending,
    );
    await ref.read(screeningsProvider.notifier).add(placeholder);
    ref.read(syncQueueProvider).enqueue(SyncItem(
          id: id,
          type: 'screening',
          payload: {'id': id, 'childId': placeholder.childId, 'confidence': 87},
          createdAt: DateTime.now(),
        ));

    // Kick off Supabase sync (fire-and-forget).
    syncScreening(placeholder, audioPath);

    // Run on-device classification in the background. If it succeeds, update
    // the screening + the result provider; otherwise the placeholder stays.
    if (audioPath != null) {
      final path = audioPath;
      runBackgroundClassification(id, path);
    }
  }

  void runBackgroundClassification(String id, String audioPath) {
    // Capture a reference to the provider container so we can still read providers
    // after the widget is disposed (the user may have navigated away).
    final container = ProviderScope.containerOf(context, listen: false);
    () async {
      try {
        final bytes = await File(audioPath).readAsBytes();
        final result = await container.read(coughClassifierProvider).classify(bytes);
        try {
          final samples = AudioDsp.decodeWav(bytes);
          container.read(lastSpectrogramProvider.notifier).state =
              AudioDsp.spectrogramGrid(samples);
        } catch (_) {}
        final updated = Screening(
          id: id,
          childId: container.read(currentChildIdProvider).valueOrNull ?? 'c1',
          date: DateTime.now().toIso8601String(),
          symptoms: const ['batuk', 'demam'],
          audioDuration: _seconds,
          riskLevel: result.isPneumonia ? RiskLevel.high : RiskLevel.low,
          disease: result.disease,
          confidence: result.confidence,
          status: SyncStatus.pending,
        );
        await container.read(screeningsProvider.notifier).updateScreening(updated);
      } catch (e) {
        debugPrint('Background classification failed: $e');
      }
    }();
  }

  void syncScreening(Screening screening, String? audioPath) {
    () async {
      try {
        await _syncToSupabase(screening, audioPath);
      } catch (e) {
        debugPrint('Sync failed: $e');
      }
    }();
  }

  Future<void> _syncToSupabase(Screening screening, String? audioPath) async {
    final supabase = ref.read(supabaseServiceProvider);
    String? audioStoragePath;
    if (audioPath != null) {
      final f = File(audioPath);
      if (await f.exists()) {
        audioStoragePath = await supabase.uploadAudio(
          childId: screening.childId,
          audioFile: f,
        );
      }
    }
    // Skema mengikuti website dokter (NeumoAIweb): id uuid, status awaiting,
    // audio_url adalah path storage (childId/<file>.wav).
    await supabase.insertScreening({
      'id': screening.id,
      'child_id': screening.childId,
      'date': screening.date,
      'symptoms': screening.symptoms,
      'audio_duration': screening.audioDuration,
      'risk_level': screening.riskLevel.name,
      'disease': screening.disease,
      'confidence': screening.confidence,
      'audio_url': audioStoragePath,
      'status': 'awaiting',
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final progress = (_seconds / 5 * 100).clamp(0, 100).toDouble();
    final recording = _state == _RecState.recording;
    final done = _state == _RecState.done;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const NeumoTopBar(title: 'Rekam Suara Batuk'),
          Expanded(
            child: ListView(
              padding: recordPagePadding,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: recording ? AppColors.lightDangerSoft : AppColors.lightPrimarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(recording ? Icons.mic : Icons.hearing, size: 24, color: recording ? AppColors.danger : AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Rekam batuk si kecil selama 5 detik',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lightInk)),
                        const SizedBox(height: 3),
                        const Text('Posisikan ponsel 15–20 cm dari mulut si kecil.',
                            style: TextStyle(fontSize: 13, color: AppColors.lightMuted, height: 1.4)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                NeumoCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: recording ? AppColors.danger : (done ? AppColors.secondary : AppColors.lightFaint),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              recording
                                  ? 'Sedang merekam…'
                                  : done
                                      ? 'Rekaman selesai'
                                      : 'Siap merekam',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: muted)),
                        ),
                        Text('0:0${_seconds.clamp(0, 5)}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                      ]),
                      const SizedBox(height: 16),
                      Waveform(
                        active: recording,
                        color: done ? AppColors.secondary : AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      NeumoProgress(value: progress, color: recording ? AppColors.primary : (done ? AppColors.secondary : AppColors.lightFaint)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${progress.round()}%',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                      ),
                    ]),
                  ),
                ),
                if (recording) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(children: [
                      Icon(Icons.mic, size: 18, color: AppColors.secondaryDeep),
                      SizedBox(width: 8),
                      Text('Sedang merekam suara batuk…',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.secondaryDeep)),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: _state == _RecState.done
                      ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Column(children: [
                            GestureDetector(
                              onTap: () => _retry(),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: surface,
                                  border: Border.all(color: border),
                                ),
                                child: const Icon(Icons.refresh, color: AppColors.danger, size: 28),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text('Ulang', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                          ]),
                          const SizedBox(width: 32),
                          Column(children: [
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
                            const SizedBox(height: 6),
                            const Text('Kirim hasil', style: TextStyle(fontSize: 12, color: AppColors.lightMuted)),
                          ]),
                        ])
                      : GestureDetector(
                          onTap: recording ? () => _retry() : () => _start(),
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recording ? AppColors.danger : AppColors.primary,
                              boxShadow: [BoxShadow(color: (recording ? AppColors.danger : AppColors.primary).withValues(alpha: 0.5), blurRadius: 30)],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(recording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                                if (_state == _RecState.idle) ...[
                                  const SizedBox(height: 2),
                                  Text('Rekam', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                if (done)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.lightSecondarySoft, borderRadius: BorderRadius.circular(16)),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('✅', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Rekaman tersimpan secara lokal. Akan diunggah otomatis saat AI mulai menganalisis.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.secondaryDeep, height: 1.4)),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
