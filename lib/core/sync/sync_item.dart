class SyncItem {
  const SyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
}
