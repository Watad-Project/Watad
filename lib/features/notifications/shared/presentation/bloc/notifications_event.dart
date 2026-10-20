part of 'notifications_bloc.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

/// Load the list, when the page opens and on pull to refresh.
final class NotificationsFetched extends NotificationsEvent {
  const NotificationsFetched();
}

/// Follow the changes while the page is open: new ones, read ones.
final class NotificationsChangesWatched extends NotificationsEvent {
  const NotificationsChangesWatched();
}

/// The user tapped [notification].
final class NotificationsOpened extends NotificationsEvent {
  const NotificationsOpened(this.notification);

  final UserNotification notification;
}

/// «تحديد الكل كمقروء».
final class NotificationsAllRead extends NotificationsEvent {
  const NotificationsAllRead();
}
