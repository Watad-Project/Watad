part of 'notifications_bloc.dart';

sealed class NotificationsEvent {
  const NotificationsEvent();
}

/// Load the list, when the page opens and on pull to refresh.
final class NotificationsFetched extends NotificationsEvent {
  const NotificationsFetched();
}

/// Add the notifications arriving while the page is open.
final class NotificationsArrivalsWatched extends NotificationsEvent {
  const NotificationsArrivalsWatched();
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
