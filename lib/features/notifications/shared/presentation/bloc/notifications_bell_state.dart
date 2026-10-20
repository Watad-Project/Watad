part of 'notifications_bell_bloc.dart';

final class NotificationsBellState {
  const NotificationsBellState({
    this.unreadCount = 0,
    this.arrived,
    this.tapped,
  });

  final int unreadCount;

  /// The last notification that arrived while the app was open, to show
  /// once in the app.
  final UserNotification? arrived;

  /// The last tapped push, to open once where it leads.
  final NotificationTap? tapped;

  NotificationsBellState copyWith({
    int? unreadCount,
    UserNotification? Function()? arrived,
    NotificationTap? Function()? tapped,
  }) {
    return NotificationsBellState(
      unreadCount: unreadCount ?? this.unreadCount,
      arrived: arrived == null ? this.arrived : arrived(),
      tapped: tapped == null ? this.tapped : tapped(),
    );
  }
}
