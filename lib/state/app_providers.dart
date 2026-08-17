import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';

import '../core/audio/cough_recorder.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/ml/cough_classifier.dart';
import '../core/services/showcase_service.dart';
import '../core/supabase/supabase_service.dart';
import '../core/sync/sync_item.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_service.dart';
import '../core/utils/password.dart';
import '../data/local/app_database.dart' hide Screening, AppNotification;
import '../data/local/repositories/local_child_repository.dart';
import '../data/local/repositories/local_notification_repository.dart';
import '../data/local/repositories/local_profile_repository.dart';
import '../data/local/repositories/local_screening_repository.dart';
import '../data/local/repositories/local_settings_repository.dart';
import '../data/mock/mock_repositories.dart';
import '../data/repositories/article_repository.dart';
import '../data/repositories/child_repository.dart';
import '../data/repositories/health_center_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/screening_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../models/app_notification.dart';
import '../models/article.dart';
import '../models/child.dart';
import '../models/health_center.dart';
import '../models/profile.dart';
import '../models/screening.dart';

// ── Repository wiring (Local Drift-first; swap here for Api later) ─────────

/// True when the bundled native sqlite3 library can be loaded. On some ABIs
/// (e.g. 32-bit x86 emulators) `sqlite3_flutter_libs` does not ship the native
/// library, so Drift persistence is unavailable. In that case we fall back to
/// in-memory Mock repositories so the app still boots and is usable.
final sqliteAvailableProvider = Provider<bool>((ref) {
  try {
    final db = sqlite3.openInMemory();
    db.dispose();
    return true;
  } catch (_) {
    return false;
  }
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => ref.watch(sqliteAvailableProvider)
        ? LocalSettingsRepository(ref.watch(appDatabaseProvider))
        : MockSettingsRepository());

final showcaseServiceProvider = Provider<ShowcaseService>(
    (ref) => ShowcaseService(ref.watch(settingsRepositoryProvider)));

final childRepositoryProvider = Provider<ChildRepository>(
    (ref) => ref.watch(sqliteAvailableProvider)
        ? LocalChildRepository(ref.watch(appDatabaseProvider))
        : MockChildRepository());

final screeningRepositoryProvider = Provider<ScreeningRepository>(
    (ref) => ref.watch(sqliteAvailableProvider)
        ? LocalScreeningRepository(ref.watch(appDatabaseProvider))
        : MockScreeningRepository());

final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => ref.watch(sqliteAvailableProvider)
        ? LocalNotificationRepository(ref.watch(appDatabaseProvider))
        : MockNotificationRepository());

final articleRepositoryProvider = Provider<ArticleRepository>((ref) => MockArticleRepository());

final healthCenterRepositoryProvider =
    Provider<HealthCenterRepository>((ref) => MockHealthCenterRepository());

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ref.watch(sqliteAvailableProvider)
        ? LocalProfileRepository(ref.watch(appDatabaseProvider))
        : MockProfileRepository());

// ── Settings / theme / onboarding ──────────────────────────────────────────

final themeKeyProvider = AsyncNotifierProvider<ThemeKeyNotifier, String>(ThemeKeyNotifier.new);

class ThemeKeyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async =>
      await ref.watch(settingsRepositoryProvider).getThemeKey() ?? 'system';

  Future<void> setThemeKey(String key) async {
    state = AsyncData(key);
    await ref.read(settingsRepositoryProvider).setThemeKey(key);
  }
}

final onboardingDoneProvider =
    AsyncNotifierProvider<OnboardingDoneNotifier, bool>(OnboardingDoneNotifier.new);

class OnboardingDoneNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      await ref.watch(settingsRepositoryProvider).isOnboardingDone();

  Future<void> complete() async {
    state = const AsyncData(true);
    await ref.read(settingsRepositoryProvider).setOnboardingDone(true);
  }
}

// ── Domain data ────────────────────────────────────────────────────────────

final childrenProvider =
    AsyncNotifierProvider<ChildrenNotifier, List<Child>>(ChildrenNotifier.new);

class ChildrenNotifier extends AsyncNotifier<List<Child>> {
  @override
  Future<List<Child>> build() => ref.watch(childRepositoryProvider).getChildren();

  Future<void> add(Child child) async {
    await ref.read(childRepositoryProvider).addChild(child);
    state = await AsyncValue.guard(() => ref.read(childRepositoryProvider).getChildren());
  }

  Future<void> updateChild(Child child) async {
    await ref.read(childRepositoryProvider).updateChild(child);
    state = await AsyncValue.guard(() => ref.read(childRepositoryProvider).getChildren());
  }

  Future<void> remove(String id) async {
    await ref.read(childRepositoryProvider).deleteChild(id);
    state = await AsyncValue.guard(() => ref.read(childRepositoryProvider).getChildren());
  }
}

final screeningsProvider =
    AsyncNotifierProvider<ScreeningsNotifier, List<Screening>>(ScreeningsNotifier.new);

class ScreeningsNotifier extends AsyncNotifier<List<Screening>> {
  @override
  Future<List<Screening>> build() =>
      ref.watch(screeningRepositoryProvider).getScreenings();

  Future<void> add(Screening screening) async {
    await ref.read(screeningRepositoryProvider).addScreening(screening);
    state = await AsyncValue.guard(() => ref.read(screeningRepositoryProvider).getScreenings());
  }

  Future<void> updateScreening(Screening screening) async {
    await ref.read(screeningRepositoryProvider).updateScreening(screening);
    state = await AsyncValue.guard(() => ref.read(screeningRepositoryProvider).getScreenings());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(NotificationsNotifier.new);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationRepositoryProvider).getNotifications();

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    state = await AsyncValue.guard(() => ref.read(notificationRepositoryProvider).getNotifications());
  }
}

final articlesProvider = FutureProvider<List<Article>>(
    (ref) => ref.watch(articleRepositoryProvider).getArticles());

final centersProvider = FutureProvider<List<HealthCenter>>(
    (ref) => ref.watch(healthCenterRepositoryProvider).getCenters());

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() => ref.watch(profileRepositoryProvider).getProfile();

  Future<void> updateProfile(Profile profile) async {
    await ref.read(profileRepositoryProvider).updateProfile(profile);
    state = AsyncData(profile);
  }
}

final currentChildIdProvider =
    AsyncNotifierProvider<CurrentChildIdNotifier, String>(CurrentChildIdNotifier.new);

class CurrentChildIdNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final saved = await ref.watch(settingsRepositoryProvider).getCurrentChildId();
    if (saved != null && saved.isNotEmpty) return saved;
    final children = await ref.read(childRepositoryProvider).getChildren();
    return children.isNotEmpty ? children.first.id : '';
  }

  Future<void> select(String id) async {
    state = AsyncData(id);
    await ref.read(settingsRepositoryProvider).setCurrentChildId(id);
  }
}

// ── Auth (single account-profile) ───────────────────────────────────────────

final authProvider =
    AsyncNotifierProvider<AuthNotifier, Profile?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    final userId = await settings.getLoggedInUserId();
    if (userId == null || userId.isEmpty) return null;
    return ref.read(profileRepositoryProvider).getProfileById(userId);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    if (await repo.emailExists(email)) {
      return 'Email sudah terdaftar. Gunakan email lain atau masuk.';
    }
    final profile = Profile(
      name: name,
      email: email,
      phone: phone,
      emoji: '👩',
      role: 'Orang Tua',
    );
    await repo.createAccount(profile, hashPassword(password));
    await ref.read(settingsRepositoryProvider).setLoggedInUserId(email);
    state = AsyncData(profile);
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final ok = await repo.verifyPassword(email, hashPassword(password));
    if (!ok) return 'Email atau kata sandi salah.';
    final profile = await repo.getProfileByEmail(email);
    await ref.read(settingsRepositoryProvider).setLoggedInUserId(email);
    state = AsyncData(profile);
    return null;
  }

  Future<void> logout() async {
    await ref.read(settingsRepositoryProvider).setLoggedInUserId(null);
    state = const AsyncData(null);
  }
}

// ── Connectivity & sync ────────────────────────────────────────────────────

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityPlusService());

final coughRecorderProvider = Provider<CoughRecorder>((ref) => CoughRecorder());

final coughClassifierProvider = Provider<CoughClassifier>((ref) => CoughClassifier());

/// Holds the spectrogram grid of the most recent screening (for display).
final lastSpectrogramProvider = StateProvider<List<List<double>>?>((ref) => null);

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService());

final syncQueueProvider = Provider<SyncQueue>((ref) => SyncQueue());

Future<void> _mockUpload(SyncItem item) async {}

final syncServiceProvider = Provider<SyncService>((ref) {
  final queue = ref.watch(syncQueueProvider);
  final service = SyncService(
    queue: queue,
    onlineStream: ref.watch(connectivityServiceProvider).isOnline,
    upload: _mockUpload,
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

final pendingSyncProvider = StreamProvider<int>((ref) {
  final queue = ref.watch(syncQueueProvider);
  final service = ref.watch(syncServiceProvider);
  return Stream.multi((controller) {
    void emit() => controller.add(queue.length);
    emit();
    final sub1 = queue.changes.listen((_) => emit());
    final sub2 = service.pendingCountStream.listen(controller.add);
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
  });
});
