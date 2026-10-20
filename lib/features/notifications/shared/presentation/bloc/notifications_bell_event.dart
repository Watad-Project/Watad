part of 'notifications_bell_bloc.dart';

sealed class NotificationsBellEvent {
  const NotificationsBellEvent();
}

/// The bell appeared: count, listen, and start push.
final class NotificationsBellStarted extends NotificationsBellEvent {
  const NotificationsBellStarted();
}

/// Count again, e.g. after the list was opened.
final class NotificationsBellCountRequested extends NotificationsBellEvent {
  const NotificationsBellCountRequested();
}

/// Listen to the notifications arriving while the app is open.
final class NotificationsBellArrivalsWatched extends NotificationsBellEvent {
  const NotificationsBellArrivalsWatched();
}

/// Listen to the pushes the user taps.
final class NotificationsBellTapsWatched extends NotificationsBellEvent {
  const NotificationsBellTapsWatched();
}
