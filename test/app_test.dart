import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neumoi_d/app.dart';
import 'package:neumoi_d/core/connectivity/connectivity_service.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/state/app_providers.dart';
import 'helpers/noop_showcase_service.dart';

class _FakeConnectivity implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  @override
  Stream<bool> get isOnline => _controller.stream;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  ProviderContainer buildContainer() {
    return ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      connectivityServiceProvider.overrideWithValue(_FakeConnectivity()),
      syncQueueProvider.overrideWithValue(SyncQueue()),
      showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
    ]);
  }

  testWidgets('app boots to splash then onboarding on first run', (tester) async {
    final connectivity = _FakeConnectivity();
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(settingsRepositoryProvider).markTourDone(true);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NeumoiApp()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('NeumoAI-D'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Skrining Batuk Anak'), findsOneWidget);
    await connectivity._controller.close();
  });

  testWidgets('app boots to home when onboarding already done', (tester) async {
    final connectivity = _FakeConnectivity();
    final container = buildContainer();
    addTearDown(container.dispose);
    await container.read(settingsRepositoryProvider).markTourDone(true);
    await container.read(onboardingDoneProvider.future);
    await container.read(onboardingDoneProvider.notifier).complete();

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NeumoiApp()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Beranda'), findsOneWidget);
    await connectivity._controller.close();
  });
}
