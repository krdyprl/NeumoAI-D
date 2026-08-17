import 'package:drift/drift.dart';

import '../../../models/child.dart';
import '../../../models/vaccination.dart' as model;
import '../../repositories/child_repository.dart';
import '../app_database.dart';

class LocalChildRepository implements ChildRepository {
  LocalChildRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Child>> getChildren() async {
    final rows = await (_db.select(_db.children)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    final vaccinations =
        await (_db.select(_db.vaccinations)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    final byChild = <String, List<model.Vaccination>>{};
    for (final v in vaccinations) {
      byChild.putIfAbsent(v.childId, () => []).add(model.Vaccination(
            id: v.id,
            name: v.name,
            date: v.date,
            done: v.done,
          ));
    }
    return [
      for (final r in rows)
        Child(
          id: r.id,
          name: r.name,
          gender: r.gender,
          birthDate: r.birthDate,
          birthWeight: r.birthWeight,
          weight: r.weight,
          height: r.height,
          emoji: r.emoji,
          medicalHistory: r.medicalHistory,
          vaccinations: byChild[r.id] ?? const [],
        ),
    ];
  }

  @override
  Future<void> addChild(Child child) async {
    await _db.transaction(() async {
      await _db.into(_db.children).insert(
            ChildrenCompanion.insert(
              id: child.id,
              name: child.name,
              gender: child.gender,
              birthDate: child.birthDate,
              birthWeight: child.birthWeight,
              weight: child.weight,
              height: child.height,
              emoji: child.emoji,
              medicalHistory: child.medicalHistory,
            ),
          );
      for (final v in child.vaccinations) {
        await _db.into(_db.vaccinations).insert(
              VaccinationsCompanion.insert(
                id: v.id,
                childId: child.id,
                name: v.name,
                date: v.date,
                done: v.done,
              ),
            );
      }
    });
  }

  @override
  Future<void> updateChild(Child child) async {
    await _db.transaction(() async {
      await (_db.update(_db.children)..where((t) => t.id.equals(child.id))).write(
            ChildrenCompanion(
              name: Value(child.name),
              gender: Value(child.gender),
              birthDate: Value(child.birthDate),
              birthWeight: Value(child.birthWeight),
              weight: Value(child.weight),
              height: Value(child.height),
              emoji: Value(child.emoji),
              medicalHistory: Value(child.medicalHistory),
            ),
          );
      await (_db.delete(_db.vaccinations)..where((t) => t.childId.equals(child.id))).go();
      for (final v in child.vaccinations) {
        await _db.into(_db.vaccinations).insert(
              VaccinationsCompanion.insert(
                id: v.id,
                childId: child.id,
                name: v.name,
                date: v.date,
                done: v.done,
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteChild(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.vaccinations)..where((t) => t.childId.equals(id))).go();
      await (_db.delete(_db.children)..where((t) => t.id.equals(id))).go();
    });
  }
}
