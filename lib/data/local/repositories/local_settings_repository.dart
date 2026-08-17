import '../../repositories/settings_repository.dart';
import '../app_database.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> _get(String key) async {
    try {
      final row = await (_db.select(_db.meta)..where((t) => t.key.equals(key)))
          .getSingleOrNull();
      return row?.value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _set(String key, String value) async {
    try {
      await _db.into(_db.meta).insertOnConflictUpdate(
          MetaCompanion.insert(key: key, value: value));
    } catch (_) {}
  }

  @override
  Future<String?> getThemeKey() async => await _get('theme');

  @override
  Future<void> setThemeKey(String key) => _set('theme', key);

  @override
  Future<bool> isOnboardingDone() async => await _get('onboarding') == '1';

  @override
  Future<void> setOnboardingDone(bool done) =>
      _set('onboarding', done ? '1' : '0');

  @override
  Future<String?> getCurrentChildId() async => await _get('currentChildId');

  @override
  Future<void> setCurrentChildId(String id) => _set('currentChildId', id);

  @override
  Future<bool> isShowcaseDone(String screen) async =>
      await _get('showcase_$screen') == '1';

  @override
  Future<void> markShowcaseDone(String screen) =>
      _set('showcase_$screen', '1');

  @override
  Future<void> resetShowcase(String screen) => _set('showcase_$screen', '0');

  @override
  Future<bool> isTourDone() async => await _get('tour_done') == '1';

  @override
  Future<void> markTourDone(bool done) =>
      _set('tour_done', done ? '1' : '0');

  @override
  Future<String?> getLoggedInUserId() async => await _get('logged_in');

  @override
  Future<void> setLoggedInUserId(String? id) async {
    if (id == null) {
      final row = await (_db.select(_db.meta)..where((t) => t.key.equals('logged_in')))
          .getSingleOrNull();
      if (row != null) {
        await (_db.delete(_db.meta)..where((t) => t.key.equals('logged_in'))).go();
      }
    } else {
      await _set('logged_in', id);
    }
  }
}
