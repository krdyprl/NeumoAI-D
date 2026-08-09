import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/features/education/screens/education_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('education lists articles and filters by category', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Edukasi Napas'), findsOneWidget);
    expect(find.text('Kenali 4 Tanda Bahaya Napas Cepat pada Anak'), findsWidgets);

    // Category filter: only Darurat article remains
    await tester.tap(find.descendant(of: find.byType(SingleChildScrollView), matching: find.text('Darurat')));
    await tester.pumpAndSettle();
    expect(find.text('Nutrisi untuk Memperkuat Daya Tahan Anak'), findsNothing);
    expect(find.text('Pertolongan Pertama saat Anak Sesak Napas'), findsOneWidget);
  });

  testWidgets('search filters by title', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Napas per Menit');
    await tester.pumpAndSettle();

    expect(find.text('Panduan Menghitung Napas per Menit Sesuai Usia'), findsOneWidget);
    expect(find.text('Pertolongan Pertama saat Anak Sesak Napas'), findsNothing);
  });

  testWidgets('tapping featured card navigates to article', (tester) async {
    final container = ProviderContainer(overrides: [
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/education',
      routes: [
        GoRoute(path: '/education', builder: (_, __) => const EducationScreen()),
        GoRoute(path: '/article', builder: (_, state) => Scaffold(body: Text('ARTIKEL ${state.uri.queryParameters['articleId']}'))),
        GoRoute(path: '/symptoms', builder: (_, __) => const Scaffold(body: Text('symptoms'))),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artikel Unggulan').first);
    await tester.pumpAndSettle();
    expect(find.text('ARTIKEL a1'), findsOneWidget);
  });
}