/// One notification of the signed-in user (`v_my_notifications`).
class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String title;
  final String body;

  /// What happened: `type` and the ids. Where a tap leads comes from it
  /// (AppNotificationLinks, ARCHITECTURE.md §13).
  final Map<String, Object?> data;

  /// When the user opened it (UTC); null while unread.
  final DateTime? readAt;

  /// When it was sent (UTC).
  final DateTime createdAt;

  bool get isRead => readAt != null;
}
