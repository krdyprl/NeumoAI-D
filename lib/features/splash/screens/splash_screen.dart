import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../state/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final done = await ref.read(onboardingDoneProvider.future);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(done ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(color: Color(0x731D7AFC), blurRadius: 40, offset: Offset(0, 12)),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.coronavirus, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('NeumoAI-D',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Skrining pneumonia pada anak',
                style: TextStyle(fontSize: 13, color: AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}