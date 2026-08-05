import 'dart:async';
import 'sync_item.dart';

class SyncQueue {
  final List<SyncItem> _items = [];
  final Set<String> _failed = {};
  final StreamController<int> _changes = StreamController<int>.broadcast();

  int get length => _items.length;
  List<SyncItem> get items => List.unmodifiable(_items);
  Stream<int> get changes => _changes.stream;

  void enqueue(SyncItem item) {
    _items.add(item);
    _changes.add(_items.length);
  }

  SyncItem? next() => _items.isEmpty ? null : _items.first;

  void remove(String id) {
    _items.removeWhere((i) => i.id == id);
    _failed.remove(id);
    _changes.add(_items.length);
  }

  void markFailed(String id) => _failed.add(id);

  bool hasFailed(String id) => _failed.contains(id);
}
