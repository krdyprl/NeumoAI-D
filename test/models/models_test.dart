import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/models/child.dart';
import 'package:neumoi_d/models/enums.dart';
import 'package:neumoi_d/models/screening.dart';

void main() {
  test('Child copyWith updates only given fields', () {
    const child = Child(
      id: 'c1',
      name: 'Arya Putra',
      gender: Gender.male,
      birthDate: '2023-03-14',
      birthWeight: 3.2,
      weight: 13.5,
      height: 92,
      emoji: 'ðŸ‘¦',
      medicalHistory: '',
    );
    final updated = child.copyWith(name: 'Arya', weight: 14);
    expect(updated.name, 'Arya');
    expect(updated.weight, 14);
    expect(updated.id, 'c1');
  });

  test('RiskLevel has correct label mapping', () {
    expect(RiskLevel.low.label, 'Rendah');
    expect(RiskLevel.medium.label, 'Sedang');
    expect(RiskLevel.high.label, 'Tinggi');
  });

  test('Screening stores symptom list and risk', () {
    const s = Screening(
      id: 's1',
      childId: 'c1',
      date: '2026-07-31T09:14:00',
      symptoms: ['batuk', 'demam'],
      audioDuration: 5,
      riskLevel: RiskLevel.high,
      disease: 'Pneumonia',
      confidence: 87,
      status: SyncStatus.synced,
    );
    expect(s.symptoms.length, 2);
    expect(s.riskLevel, RiskLevel.high);
  });
}