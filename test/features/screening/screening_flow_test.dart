import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/theme/app_theme.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/features/screening/screens/processing_screen.dart';
import 'package:neumoi_d/features/screening/screens/record_screen.dart';
import 'package:neumoi_d/features/screening/screens/symptoms_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../helpers/fake_cough_recorder.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ShowcaseView.register(enableShowcase: false);
  });
  tearDown(() => ShowcaseView.get().unregister());

  testWidgets('symptoms screen advances to record', (tester) async {
    final container = ProviderContainer(overrides: [
      childRepositoryProvider.overrideWithValue(MockChildRepository()),
      screeningRepositoryProvider.overrideWithValue(MockScreeningRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      coughRecorderProvider.overrideWithValue(FakeCoughRecorder()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/symptoms',
      routes: [
        GoRoute(path: '/symptoms', builder: (_, __) => const SymptomsScreen()),
        GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Gejala'), findsOneWidget);
    await tester.tap(find.text('Lanjut Rekam Suara →'));
    await tester.pumpAndSettle();
    expect(find.text('Rekam Suara Batuk'), findsOneWidget);
  });

  testWidgets('record flow submits a pending screening and enqueues sync', (tester) async {
    final queue = SyncQueue();
    final container = ProviderContainer(overrides: [
      childRepositoryProvider.overrideWithValue(MockChildRepository()),
      screeningRepositoryProvider.overrideWithValue(MockScreeningRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      coughRecorderProvider.overrideWithValue(FakeCoughRecorder()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(queue),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/record',
      routes: [
        GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
        GoRoute(path: '/processing', builder: (_, __) => const ProcessingScreen()),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rekam'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Rekaman selesai'), findsOneWidget);

    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    expect(find.text('AI Sedang Menganalisis…'), findsOneWidget);
    expect(queue.length, 1);
    expect(queue.items.single.type, 'screening');
  });
}
