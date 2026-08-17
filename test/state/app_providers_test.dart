import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/state/app_providers.dart';

void main() {
  ProviderContainer buildContainer() => ProviderContainer(overrides: [
        childRepositoryProvider.overrideWithValue(MockChildRepository()),
        screeningRepositoryProvider.overrideWithValue(MockScreeningRepository()),
        settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      ]);

  test('providers load from mock repositories', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final children = await container.read(childrenProvider.future);
    expect(children.length, 2);

    final theme = await container.read(themeKeyProvider.future);
    expect(theme, 'system');

    final currentId = await container.read(currentChildIdProvider.future);
    expect(currentId, 'c1');

    final screenings = await container.read(screeningsProvider.future);
    expect(screenings.length, 4);
  });

  test('currentChildIdProvider.select updates persisted value', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await container.read(currentChildIdProvider.notifier).select('c2');
    expect(container.read(currentChildIdProvider).value, 'c2');
  });
}
