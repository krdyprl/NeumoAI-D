import 'package:drift/drift.dart';

import '../../../core/utils/password.dart';
import '../../../models/profile.dart' as model;
import '../../repositories/profile_repository.dart';
import '../app_database.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._db);

  final AppDatabase _db;

  /// Demo account untuk pengujian di HP.
  static const String demoEmail = 'demoneumoaid@gmail.com';
  static const String demoPassword = '0k8a0r2d0y5naN';

  /// Seeds the demo account when the accounts table is empty (fresh install).
  Future<void> _seedDemoIfEmpty() async {
    final count = await (_db.select(_db.accounts)..limit(1)).get();
    if (count.isNotEmpty) return;
    try {
      await _db.into(_db.accounts).insert(
            AccountsCompanion.insert(
              id: demoEmail,
              name: 'Demo NeumoAid',
              email: demoEmail,
              phone: '+62 812-0000-0000',
              emoji: '👩',
              role: 'Orang Tua',
              passwordHash: hashPassword(demoPassword),
              createdAt: DateTime.now(),
            ),
          );
    } catch (_) {}
  }

  @override
  Future<model.Profile> getProfile() async {
    await _seedDemoIfEmpty();
    final id = await _getLoggedInId();
    if (id == null) {
      final first = await (_db.select(_db.accounts)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .getSingleOrNull();
      if (first == null) return const model.Profile(name: '', email: '', phone: '', emoji: '👩', role: 'Orang Tua');
      return _toModel(first);
    }
    final row = await _getById(id);
    if (row == null) return const model.Profile(name: '', email: '', phone: '', emoji: '👩', role: 'Orang Tua');
    return _toModel(row);
  }

  @override
  Future<void> updateProfile(model.Profile profile) async {
    final id = await _getLoggedInId();
    if (id == null) return;
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
          AccountsCompanion(
            name: Value(profile.name),
            email: Value(profile.email),
            phone: Value(profile.phone),
            emoji: Value(profile.emoji),
            role: Value(profile.role),
          ),
        );
  }

  @override
  Future<model.Profile?> getProfileById(String id) async {
    final row = await _getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<model.Profile?> getProfileByEmail(String email) async {
    final row = await (_db.select(_db.accounts)..where((t) => t.email.equals(email)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<bool> emailExists(String email) async =>
      await (_db.select(_db.accounts)..where((t) => t.email.equals(email))).getSingleOrNull() != null;

  @override
  Future<void> createAccount(model.Profile profile, String passwordHash) async {
    await _db.into(_db.accounts).insert(
          AccountsCompanion.insert(
            id: profile.email,
            name: profile.name,
            email: profile.email,
            phone: profile.phone,
            emoji: profile.emoji,
            role: profile.role,
            passwordHash: passwordHash,
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<bool> verifyPassword(String email, String passwordHash) async {
    await _seedDemoIfEmpty();
    final row = await (_db.select(_db.accounts)..where((t) => t.email.equals(email)))
        .getSingleOrNull();
    return row != null && row.passwordHash == passwordHash;
  }

  Future<Account?> _getById(String id) async =>
      await (_db.select(_db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String?> _getLoggedInId() async {
    final row = await (_db.select(_db.meta)..where((t) => t.key.equals('logged_in')))
        .getSingleOrNull();
    return row?.value;
  }

  model.Profile _toModel(Account row) => model.Profile(
        name: row.name,
        email: row.email,
        phone: row.phone,
        emoji: row.emoji,
        role: row.role,
      );
}
