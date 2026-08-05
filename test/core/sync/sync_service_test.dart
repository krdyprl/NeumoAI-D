import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/core/sync/sync_item.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';
import 'package:neumoi_d/core/sync/sync_service.dart';

void main() {
  test('SyncService drains queue when online', () async {
    final q = SyncQueue();
    q.enqueue(SyncItem(id: 'a', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    final uploaded = <String>[];
    final onlineController = StreamController<bool>();
    final service = SyncService(
      queue: q,
      onlineStream: onlineController.stream,
      upload: (item) async => uploaded.add(item.id),
    );
    service.start();
    onlineController.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(uploaded, ['a']);
    expect(q.length, 0);
    await onlineController.close();
    service.dispose();
  });

  test('SyncService keeps failed item queued and retries', () async {
    final q = SyncQueue();
    q.enqueue(SyncItem(id: 'a', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    var attempts = 0;
    final onlineController = StreamController<bool>();
    final service = SyncService(
      queue: q,
      onlineStream: onlineController.stream,
      upload: (item) async {
        attempts++;
        if (attempts == 1) throw Exception('network');
      },
    );
    service.start();
    onlineController.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(attempts, 1);
    expect(q.length, 1);
    onlineController.add(true); // retry on next online pulse
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(attempts, 2);
    expect(q.length, 0);
    await onlineController.close();
    service.dispose();
  });
}