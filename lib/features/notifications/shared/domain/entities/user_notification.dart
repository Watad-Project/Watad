import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';

/// One notification of the signed-in user (`v_my_notifications`).
class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.target,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;

  /// Where a tap leads; null when it opens nothing.
  final NotificationTarget? target;

  /// When the user opened it (UTC); null while unread.
  final DateTime? readAt;

  /// When it was sent (UTC).
  final DateTime createdAt;

  bool get isRead => readAt != null;
}
