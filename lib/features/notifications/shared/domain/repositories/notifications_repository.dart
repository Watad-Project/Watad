import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';

abstract interface class NotificationsRepository {
  /// The user's notifications, newest first.
  Future<Result<List<UserNotification>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  /// Marks [ids] read, or all of them when null.
  Future<Result<void>> markRead(List<String>? ids);

  /// Each new notification of the user, as it arrives (Realtime).
  Stream<Result<UserNotification>> watchNew();

  /// Starts push on this device for the signed-in user: OneSignal signs the
  /// device in as them, and asks permission to notify.
  Future<Result<void>> startPush();

  /// Where each tapped push leads.
  Stream<Result<NotificationTarget>> watchTaps();
}
