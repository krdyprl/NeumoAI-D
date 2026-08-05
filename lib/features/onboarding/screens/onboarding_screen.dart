import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neumo_button.dart';
import '../../../state/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  static const _slides = [
    (Icons.mic, 'Skrining Batuk Anak', 'Rekam batuk si kecil selama 5 detik dan biarkan AI membantu deteksi dini.'),
    (Icons.waves, 'Analisis AI', 'Suara batuk dianalisis untuk menilai indikasi pneumonia dengan penjelasan yang mudah dipahami.'),
    (Icons.track_changes, 'Tetap Terpantau', 'Pantau pertumbuhan, vaksinasi, dan riwayat kesehatan anak dalam satu aplikasi.'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingDoneProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInk
        : AppColors.lightInk;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Lewati',
                    style: TextStyle(color: AppColors.lightMuted, fontSize: 13)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final (icon, title, desc) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0x291D7AFC), Color(0x293ECF8E)],
                            ),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(title,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink)),
                        const SizedBox(height: 12),
                        Text(desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.lightMuted, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.primary : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: NeumoButton(
                expand: true,
                size: NeumoSize.lg,
                label: _index == _slides.length - 1 ? 'Mulai' : 'Lanjut',
                onPressed: () {
                  if (_index == _slides.length - 1) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}