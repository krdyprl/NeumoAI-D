import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/tour_controller.dart';
import 'state/app_providers.dart';

class NeumoiApp extends ConsumerStatefulWidget {
  const NeumoiApp({super.key});

  @override
  ConsumerState<NeumoiApp> createState() => _NeumoiAppState();
}

class _NeumoiAppState extends ConsumerState<NeumoiApp> {
  @override
  void initState() {
    super.initState();
    ref.read(supabaseServiceProvider).init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showcaseServiceProvider).registerGlobal(
        onStepComplete: (index, key) =>
            ref.read(tourControllerProvider.notifier).onStepComplete(index, key),
        onSkip: () => ref.read(tourControllerProvider.notifier).skip(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeKey = ref.watch(themeKeyProvider).valueOrNull ?? 'system';
    final mode = switch (themeKey) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'NeumoAI-D',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
