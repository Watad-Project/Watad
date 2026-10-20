import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';

/// A push the user tapped: which notification it was, and where it leads.
class NotificationTap {
  const NotificationTap({this.notificationId, this.target});

  /// To mark it read; null for a push sent outside the app's notifications.
  final String? notificationId;

  /// Null when it opens nothing.
  final NotificationTarget? target;
}
