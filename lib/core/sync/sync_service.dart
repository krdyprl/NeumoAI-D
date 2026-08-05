import 'dart:async';
import 'sync_item.dart';
import 'sync_queue.dart';

class SyncService {
  SyncService({
    required this.queue,
    required Stream<bool> onlineStream,
    required this.upload,
  }) : _onlineStream = onlineStream;

  final SyncQueue queue;
  final Future<void> Function(SyncItem item) upload;
  final Stream<bool> _onlineStream;

  final _pendingController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingController.stream;
  int get pendingCount => queue.length;

  StreamSubscription<bool>? _sub;
  bool _online = false;
  bool _draining = false;

  void start() {
    _sub = _onlineStream.listen((online) {
      _online = online;
      _pendingController.add(queue.length);
      if (online) unawaited(_drain());
    });
  }

  void dispose() {
    _sub?.cancel();
    _pendingController.close();
  }

  Future<void> _drain() async {
    if (_draining || !_online) return;
    _draining = true;
    try {
      while (_online && queue.length > 0) {
        final item = queue.next();
        if (item == null) break;
        try {
          await upload(item);
          queue.remove(item.id);
        } on Exception {
          queue.markFailed(item.id);
          break; // stop on first failure; retry on next pulse
        }
      }
    } finally {
      _draining = false;
      _pendingController.add(queue.length);
    }
  }
}
