/// Widgets one feature lends to another feature's screens, without either
/// importing the other: the lending feature registers the widget in its
/// injection file as `getIt.registerFactory<Widget>(…, instanceName: <name>)`,
/// and the borrowing feature's injection file passes
/// `getIt<Widget>(instanceName: <name>)` to its page.
abstract final class AppSlots {
  /// The bell with the unread count, on each role's home (notifications).
  static const String notificationsBell = 'notifications-bell';
}
