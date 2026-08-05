import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/app_providers.dart';

class NeumoiApp extends ConsumerWidget {
  const NeumoiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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