import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/education/screens/article_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('article screen shows article and navigates to symptoms', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/article?articleId=a3',
      routes: [
        GoRoute(path: '/article', builder: (_, state) => ArticleScreen(articleId: state.uri.queryParameters['articleId'])),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Panduan Menghitung Napas per Menit Sesuai Usia'), findsOneWidget);
    expect(find.text('Poin Penting'), findsOneWidget);
    expect(find.text('Kapan Harus ke Dokter?'), findsWidgets);

    await tester.tap(find.text('Sudah punya gejala? Cek sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('symptoms'), findsOneWidget);
  });

  testWidgets('article screen falls back to first article', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildLightTheme(), home: const ArticleScreen(articleId: 'does-not-exist')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kenali 4 Tanda Bahaya Napas Cepat pada Anak'), findsOneWidget);
  });
}