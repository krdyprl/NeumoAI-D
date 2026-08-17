import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/core/services/tour_controller.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/state/app_providers.dart';
import '../../helpers/noop_showcase_service.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
    ]);
    addTearDown(container.dispose);
  });

  group('TourController', () {
    test('start does not run when tour already done', () async {
      final settings = MockSettingsRepository();
      final c = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
      ]);
      addTearDown(c.dispose);
      await settings.markTourDone(true);

      await c.read(tourControllerProvider.notifier).start();
      expect(c.read(tourControllerProvider.notifier).isRunning, isFalse);
    });

    test('start runs when tour not done', () async {
      await container.read(tourControllerProvider.notifier).start();
      expect(container.read(tourControllerProvider.notifier).isRunning, isTrue);
    });

    test('onStepComplete on last step of last route finishes and marks done',
        () async {
      final settings = MockSettingsRepository();
      final c = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
      ]);
      addTearDown(c.dispose);

      final tour = c.read(tourControllerProvider.notifier);
      // Register final route steps
      final key = GlobalKey();
      tour.registerSteps('/profile', [TourStep(key, 'P', 'desc')]);
      await tour.start();

      // Move to last route (profile)
      tour.goToRoute(TourController.tourRoutes.length - 1);
      // Completing the single last step finishes the tour
      tour.onStepComplete(0, key);

      expect(tour.isRunning, isFalse);
      expect(await settings.isTourDone(), isTrue);
    });

    test('reset clears the done flag and stops running', () async {
      final settings = MockSettingsRepository();
      final c = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
      ]);
      addTearDown(c.dispose);

      final tour = c.read(tourControllerProvider.notifier);
      await tour.start();
      await tour.finish();
      expect(await settings.isTourDone(), isTrue);

      await tour.reset();
      expect(await settings.isTourDone(), isFalse);
      expect(tour.isRunning, isFalse);
    });

    test('skip stops the tour without marking done', () async {
      final settings = MockSettingsRepository();
      final c = ProviderContainer(overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        showcaseServiceProvider.overrideWithValue(NoopShowcaseService()),
      ]);
      addTearDown(c.dispose);

      final tour = c.read(tourControllerProvider.notifier);
      await tour.start();
      tour.skip();
      expect(tour.isRunning, isFalse);
      expect(await settings.isTourDone(), isFalse);
    });
  });
}
