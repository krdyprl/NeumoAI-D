import 'package:drift/drift.dart';

import '../../../models/app_notification.dart' as model;
import '../../repositories/notification_repository.dart';
import '../app_database.dart';

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<model.AppNotification>> getNotifications() async {
    final rows = await _db.select(_db.appNotifications).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> markRead(String id) async {
    await (_db.update(_db.appNotifications)..where((t) => t.id.equals(id)))
        .write(AppNotificationsCompanion(read: const Value(true)));
  }

  model.AppNotification _toModel(AppNotification row) => model.AppNotification(
        id: row.id,
        type: row.type,
        title: row.title,
        body: row.body,
        time: row.time,
        read: row.read,
      );
}
