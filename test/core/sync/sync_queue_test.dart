import 'package:flutter_test/flutter_test.dart';
import 'package:neumoi_d/core/sync/sync_item.dart';
import 'package:neumoi_d/core/sync/sync_queue.dart';

void main() {
  test('enqueue and length', () {
    final q = SyncQueue();
    q.enqueue(SyncItem(id: 'a', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    q.enqueue(SyncItem(id: 'b', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    expect(q.length, 2);
  });

  test('next returns first and remove drops it', () {
    final q = SyncQueue();
    q.enqueue(SyncItem(id: 'a', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    final item = q.next();
    expect(item?.id, 'a');
    q.remove(item!.id);
    expect(q.length, 0);
  });

  test('markFailed keeps item but flags it', () {
    final q = SyncQueue();
    q.enqueue(SyncItem(id: 'a', type: 'screening', payload: {}, createdAt: DateTime(2026)));
    q.markFailed('a');
    expect(q.hasFailed('a'), isTrue);
    expect(q.length, 1);
  });
}