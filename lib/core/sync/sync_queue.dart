import 'sync_item.dart';

class SyncQueue {
  final List<SyncItem> _items = [];
  final Set<String> _failed = {};

  int get length => _items.length;
  List<SyncItem> get items => List.unmodifiable(_items);

  void enqueue(SyncItem item) {
    _items.add(item);
  }

  SyncItem? next() => _items.isEmpty ? null : _items.first;

  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
    _failed.remove(id);
  }

  void markFailed(String id) => _failed.add(id);

  bool hasFailed(String id) => _failed.contains(id);
}
