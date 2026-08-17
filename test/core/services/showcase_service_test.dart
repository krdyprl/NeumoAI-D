import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/core/services/showcase_service.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';

void main() {
  group('ShowcaseService', () {
    test('shouldShow returns true before showcase is seen', () async {
      final service = ShowcaseService(MockSettingsRepository());
      expect(await service.shouldShow('home'), isTrue);
    });

    test('shouldShow returns false after markDone', () async {
      final service = ShowcaseService(MockSettingsRepository());
      await service.markDone('home');
      expect(await service.shouldShow('home'), isFalse);
    });

    test('resetShowcase makes shouldShow return true again', () async {
      final service = ShowcaseService(MockSettingsRepository());
      await service.markDone('home');
      await service.resetShowcase('home');
      expect(await service.shouldShow('home'), isTrue);
    });

    test('showcase state is per screen', () async {
      final service = ShowcaseService(MockSettingsRepository());
      await service.markDone('home');
      expect(await service.shouldShow('home'), isFalse);
      expect(await service.shouldShow('education'), isTrue);
    });
  });
}
