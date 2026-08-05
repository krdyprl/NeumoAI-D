import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/connectivity/connectivity_service.dart';
import '../core/sync/sync_item.dart';
import '../core/sync/sync_queue.dart';
import '../core/sync/sync_service.dart';
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

// ── Repository wiring (Mock-first; swap here for Api/local later) ─────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => MockSettingsRepository());

final childRepositoryProvider = Provider<ChildRepository>((ref) => MockChildRepository());

final screeningRepositoryProvider = Provider<ScreeningRepository>((ref) => MockScreeningRepository());

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => MockNotificationRepository());

final articleRepositoryProvider = Provider<ArticleRepository>((ref) => MockArticleRepository());

final healthCenterRepositoryProvider = Provider<HealthCenterRepository>((ref) => MockHealthCenterRepository());

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => MockProfileRepository());

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

// ── Connectivity & sync ────────────────────────────────────────────────────

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityPlusService());

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
