import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../models/screening.dart' as model;
import '../../repositories/screening_repository.dart';
import '../app_database.dart';

class LocalScreeningRepository implements ScreeningRepository {
  LocalScreeningRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<model.Screening>> getScreenings() async {
    final rows = await (_db.select(_db.screenings)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<model.Screening>> getScreeningsForChild(String childId) async {
    final rows = await (_db.select(_db.screenings)
          ..where((t) => t.childId.equals(childId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> addScreening(model.Screening screening) async {
    await _db.into(_db.screenings).insert(
          ScreeningsCompanion.insert(
            id: screening.id,
            childId: screening.childId,
            date: DateTime.parse(screening.date),
            symptoms: jsonEncode(screening.symptoms),
            audioDuration: screening.audioDuration,
            riskLevel: screening.riskLevel,
            disease: screening.disease,
            confidence: screening.confidence,
            status: screening.status,
          ),
        );
  }

  @override
  Future<void> updateScreening(model.Screening screening) async {
    await (_db.update(_db.screenings)..where((t) => t.id.equals(screening.id))).write(
      ScreeningsCompanion(
        date: Value(DateTime.parse(screening.date)),
        symptoms: Value(jsonEncode(screening.symptoms)),
        audioDuration: Value(screening.audioDuration),
        riskLevel: Value(screening.riskLevel),
        disease: Value(screening.disease),
        confidence: Value(screening.confidence),
        status: Value(screening.status),
      ),
    );
  }

  model.Screening _toModel(Screening row) => model.Screening(
        id: row.id,
        childId: row.childId,
        date: row.date.toIso8601String(),
        symptoms: _decodeSymptoms(row.symptoms),
        audioDuration: row.audioDuration,
        riskLevel: row.riskLevel,
        disease: row.disease,
        confidence: row.confidence,
        status: row.status,
      );

  List<String> _decodeSymptoms(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return const [];
  }
}
