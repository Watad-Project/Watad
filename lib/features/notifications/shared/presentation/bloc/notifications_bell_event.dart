part of 'notifications_bell_bloc.dart';

sealed class NotificationsBellEvent {
  const NotificationsBellEvent();
}

/// The bell appeared: count, listen, and ask permission to notify.
final class NotificationsBellStarted extends NotificationsBellEvent {
  const NotificationsBellStarted();
}

/// Count again, e.g. after the list was opened.
final class NotificationsBellCountRequested extends NotificationsBellEvent {
  const NotificationsBellCountRequested();
}

/// Listen to the changes to the user's notifications while the app is open.
final class NotificationsBellChangesWatched extends NotificationsBellEvent {
  const NotificationsBellChangesWatched();
}

/// Listen to the pushes the user taps.
final class NotificationsBellTapsWatched extends NotificationsBellEvent {
  const NotificationsBellTapsWatched();
}
