import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../models/enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Children,
    Vaccinations,
    Screenings,
    ScreeningSync,
    AppNotifications,
    Meta,
    Accounts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'neumoi_d'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
