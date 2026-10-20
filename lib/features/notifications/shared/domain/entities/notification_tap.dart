/// A push the user tapped: which notification it was, and its data.
class NotificationTap {
  const NotificationTap({this.notificationId, this.data = const {}});

  /// To mark it read; null for a push sent outside the app's notifications.
  final String? notificationId;

  /// The notification's `data`: `type` and the ids.
  final Map<String, Object?> data;
}
