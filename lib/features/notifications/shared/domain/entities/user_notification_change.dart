import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';

/// A change to one of the user's notifications, live: a new one arrived
/// ([isNew]), or one was read (on this device or another).
class UserNotificationChange {
  const UserNotificationChange({
    required this.notification,
    required this.isNew,
  });

  /// The notification as it is now.
  final UserNotification notification;
  final bool isNew;
}
