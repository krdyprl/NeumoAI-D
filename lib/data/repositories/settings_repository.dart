abstract class SettingsRepository {
  Future<String?> getThemeKey();
  Future<void> setThemeKey(String key);
  Future<bool> isOnboardingDone();
  Future<void> setOnboardingDone(bool done);
  Future<String?> getCurrentChildId();
  Future<void> setCurrentChildId(String id);
}
