import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/data/local/app_database.dart';
import 'package:neumoi_d/models/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('insert and read child', () async {
    await db.into(db.children).insert(ChildrenCompanion.insert(
          id: 'c1',
          name: 'Arya Putra',
          gender: Gender.male,
          birthDate: '2023-03-14',
          birthWeight: 3.2,
          weight: 13.5,
          height: 92,
          emoji: '👦',
          medicalHistory: '',
        ));
    final rows = await db.select(db.children).get();
    expect(rows.single.name, 'Arya Putra');
    expect(rows.single.gender, Gender.male);
  });

  test('insert and read screening with enums', () async {
    await db.into(db.screenings).insert(ScreeningsCompanion.insert(
          id: 's1',
          childId: 'c1',
          date: DateTime(2026, 7, 31, 9, 14),
          symptoms: '["batuk","demam"]',
          audioDuration: 5,
          riskLevel: RiskLevel.high,
          disease: 'Pneumonia',
          confidence: 87,
          status: SyncStatus.pending,
        ));
    final rows = await db.select(db.screenings).get();
    expect(rows.single.riskLevel, RiskLevel.high);
    expect(rows.single.status, SyncStatus.pending);
  });

  test('meta upsert by key', () async {
    await db.into(db.meta).insertOnConflictUpdate(
        MetaCompanion.insert(key: 'theme', value: 'dark'));
    final v = await (db.select(db.meta)..where((t) => t.key.equals('theme')))
        .getSingleOrNull();
    expect(v?.value, 'dark');
  });
}
