import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';

abstract interface class NotificationsRepository {
  /// The user's notifications, newest first.
  Future<Result<List<UserNotification>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  /// Marks [ids] read, or all of them when null.
  Future<Result<void>> markRead(List<String>? ids);

  /// Each change to the user's notifications, as it happens (Realtime): a
  /// new one, or one read.
  Stream<Result<UserNotificationChange>> watchChanges();

  /// Starts push on this device for the signed-in user: OneSignal signs the
  /// device in as them, and asks permission to notify.
  Future<Result<void>> startPush();

  /// Where each tapped push leads.
  Stream<Result<NotificationTarget>> watchTaps();
}
