import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/data/mock/mock_data.dart';
import 'package:neumoi_d/data/mock/mock_repositories.dart';
import 'package:neumoi_d/models/child.dart';
import 'package:neumoi_d/models/enums.dart';
import 'package:neumoi_d/models/screening.dart';

void main() {
  test('mock data matches original app snapshot', () {
    expect(MockData.children.length, 2);
    expect(MockData.screenings.length, 4);
    expect(MockData.articles.length, 6);
    expect(MockData.notifications.length, 4);
    expect(MockData.centers.length, 3);
    expect(MockData.profile.name, 'Ibu Sari');
  });

  test('MockChildRepository CRUD', () async {
    final repo = MockChildRepository();
    final initial = await repo.getChildren();
    expect(initial.length, 2);

    await repo.addChild(const Child(
      id: 'c3',
      name: 'Budi',
      gender: Gender.male,
      birthDate: '2024-01-01',
      birthWeight: 3.0,
      weight: 10.0,
      height: 80,
      emoji: '👶',
    ));
    expect((await repo.getChildren()).length, 3);

    await repo.deleteChild('c3');
    expect((await repo.getChildren()).length, 2);
  });

  test('MockScreeningRepository add inserts at front', () async {
    final repo = MockScreeningRepository();
    await repo.addScreening(const Screening(
      id: 's9',
      childId: 'c1',
      date: '2026-08-01T08:00:00',
      symptoms: ['batuk'],
      audioDuration: 5,
      riskLevel: RiskLevel.low,
      disease: 'Pneumonia',
      confidence: 10,
      status: SyncStatus.pending,
    ));
    final list = await repo.getScreenings();
    expect(list.first.id, 's9');
  });

  test('MockSettingsRepository stores values', () async {
    final repo = MockSettingsRepository();
    expect(await repo.getThemeKey(), isNull);
    await repo.setThemeKey('dark');
    expect(await repo.getThemeKey(), 'dark');
    await repo.setOnboardingDone(true);
    expect(await repo.isOnboardingDone(), isTrue);
  });

  test('MockSettingsRepository tracks showcase state', () async {
    final repo = MockSettingsRepository();
    expect(await repo.isShowcaseDone('home'), isFalse);
    await repo.markShowcaseDone('home');
    expect(await repo.isShowcaseDone('home'), isTrue);
    await repo.resetShowcase('home');
    expect(await repo.isShowcaseDone('home'), isFalse);
  });
}
