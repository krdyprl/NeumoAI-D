enum Gender { male, female }

enum RiskLevel {
  low('Rendah', 'low'),
  medium('Sedang', 'medium'),
  high('Tinggi', 'high');

  const RiskLevel(this.label, this.key);
  final String label;
  final String key;

  static RiskLevel fromKey(String key) =>
      RiskLevel.values.firstWhere((r) => r.key == key, orElse: () => RiskLevel.low);
}

enum SyncStatus { pending, synced, failed }

enum NotifType { vaccination, reminder, ai, medical }

enum ThemeModeKey {
  light('light'),
  dark('dark'),
  system('system');

  const ThemeModeKey(this.key);
  final String key;
}
