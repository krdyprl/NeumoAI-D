import '../../models/app_notification.dart';
import '../../models/article.dart';
import '../../models/child.dart';
import '../../models/health_center.dart';
import '../../models/profile.dart';
import '../../models/screening.dart';
import '../repositories/article_repository.dart';
import '../repositories/child_repository.dart';
import '../repositories/health_center_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/screening_repository.dart';
import '../repositories/settings_repository.dart';
import 'mock_data.dart';

class MockSettingsRepository implements SettingsRepository {
  final Map<String, String> _store = {};

  @override
  Future<String?> getThemeKey() async => _store['theme'];
  @override
  Future<void> setThemeKey(String key) async => _store['theme'] = key;
  @override
  Future<bool> isOnboardingDone() async => _store['onboarding'] == '1';
  @override
  Future<void> setOnboardingDone(bool done) async =>
      _store['onboarding'] = done ? '1' : '0';
  @override
  Future<String?> getCurrentChildId() async => _store['currentChildId'];
  @override
  Future<void> setCurrentChildId(String id) async =>
      _store['currentChildId'] = id;
}

class MockChildRepository implements ChildRepository {
  MockChildRepository([List<Child>? initial])
      : _children = List.of(initial ?? MockData.children);

  final List<Child> _children;

  @override
  Future<List<Child>> getChildren() async => List.of(_children);

  @override
  Future<void> addChild(Child child) async => _children.add(child);

  @override
  Future<void> updateChild(Child child) async {
    final i = _children.indexWhere((c) => c.id == child.id);
    if (i >= 0) _children[i] = child;
  }

  @override
  Future<void> deleteChild(String id) async =>
      _children.removeWhere((c) => c.id == id);
}

class MockScreeningRepository implements ScreeningRepository {
  MockScreeningRepository([List<Screening>? initial])
      : _screenings = List.of(initial ?? MockData.screenings);

  final List<Screening> _screenings;

  @override
  Future<List<Screening>> getScreenings() async => List.of(_screenings);

  @override
  Future<List<Screening>> getScreeningsForChild(String childId) async =>
      List.of(_screenings.where((s) => s.childId == childId));

  @override
  Future<void> addScreening(Screening screening) async {
    _screenings.insert(0, screening);
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository([List<AppNotification>? initial])
      : _notifications = List.of(initial ?? MockData.notifications);

  final List<AppNotification> _notifications;

  @override
  Future<List<AppNotification>> getNotifications() async =>
      List.of(_notifications);

  @override
  Future<void> markRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i >= 0) {
      final n = _notifications[i];
      _notifications[i] = AppNotification(
        id: n.id, type: n.type, title: n.title, body: n.body, time: n.time, read: true,
      );
    }
  }
}

class MockArticleRepository implements ArticleRepository {
  @override
  Future<List<Article>> getArticles() async => List.of(MockData.articles);
}

class MockHealthCenterRepository implements HealthCenterRepository {
  @override
  Future<List<HealthCenter>> getCenters() async => List.of(MockData.centers);
}

class MockProfileRepository implements ProfileRepository {
  Profile _profile = MockData.profile;

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<void> updateProfile(Profile profile) async => _profile = profile;
}
