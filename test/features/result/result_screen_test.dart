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
import 'package:neumoi_d/features/result/screens/result_screen.dart';
import 'package:neumoi_d/state/app_providers.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('result screen shows latest high-risk screening', (tester) async {
    final container = ProviderContainer(overrides: [
      childRepositoryProvider.overrideWithValue(MockChildRepository()),
      screeningRepositoryProvider.overrideWithValue(MockScreeningRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/result',
      routes: [GoRoute(path: '/result', builder: (_, __) => const ResultScreen())],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router, theme: buildLightTheme()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Risiko Tinggi'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('Spektrogram'), findsOneWidget);
    expect(find.text('Grad-CAM'), findsOneWidget);
    expect(find.text('Faktor yang Memengaruhi'), findsOneWidget);
  });
}
