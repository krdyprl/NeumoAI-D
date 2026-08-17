abstract class SettingsRepository {
  Future<String?> getThemeKey();
  Future<void> setThemeKey(String key);
  Future<bool> isOnboardingDone();
  Future<void> setOnboardingDone(bool done);
  Future<String?> getCurrentChildId();
  Future<void> setCurrentChildId(String id);
  Future<bool> isShowcaseDone(String screen);
  Future<void> markShowcaseDone(String screen);
  Future<void> resetShowcase(String screen);
  Future<bool> isTourDone();
  Future<void> markTourDone(bool done);
  Future<String?> getLoggedInUserId();
  Future<void> setLoggedInUserId(String? id);
}
