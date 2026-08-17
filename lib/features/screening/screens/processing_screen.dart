import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/waveform.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  static const _steps = [
    'Mengunggah rekaman audio',
    'Mengekstrak fitur akustik',
    'Menjalankan model AI',
    'Menyusun laporan hasil',
  ];

  int _active = 2;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _active = 3);
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/result');
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.secondary]),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [BoxShadow(color: Color(0x731D7AFC), blurRadius: 50, offset: Offset(0, 16))],
                        ),
                        child: const Waveform(active: false, barCount: 12, color: Colors.white, height: 56),
                      ),
                      const SizedBox(height: 28),
                      const Text('AI Sedang Menganalisis…',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Memproses gelombang suara batuk si kecil.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.lightMuted)),
                      const SizedBox(height: 32),
                      for (var i = 0; i < _steps.length; i++) ...[
                        Row(children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i < _active ? AppColors.secondary : (i == _active ? AppColors.primary : AppColors.lightSurface2),
                              shape: BoxShape.circle,
                            ),
                            child: i < _active
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : Text('${i + 1}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_steps[i],
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    color: i < _active ? AppColors.secondaryDeep : (i == _active ? AppColors.primary : AppColors.lightFaint))),
                          ),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 16),
                      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cloud_off, size: 14, color: AppColors.secondary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Mode offline aktif · hasil akan disimpan saat koneksi kembali',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.lightFaint)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
