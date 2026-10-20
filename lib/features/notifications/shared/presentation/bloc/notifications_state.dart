part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, success, failure }

final class NotificationsState {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.failure,
  });

  final NotificationsStatus status;

  /// Newest first.
  final List<UserNotification> notifications;

  /// Why the list couldn't load.
  final Failure? failure;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<UserNotification>? notifications,
    Failure? Function()? failure,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
