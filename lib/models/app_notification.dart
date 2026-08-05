import 'enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });

  final String id;
  final NotifType type;
  final String title;
  final String body;
  final String time;
  final bool read;
}
