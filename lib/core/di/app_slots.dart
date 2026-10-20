import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// Widgets one feature lends to another feature's screens, without either
/// importing the other: the lending feature registers the widget in its
/// injection file as `getIt.registerFactory<Widget>(…, instanceName: <name>)`,
/// and the borrowing feature's injection file passes
/// `AppSlots.widget(getIt, <name>)` to its page.
abstract final class AppSlots {
  /// The bell with the unread count, on each role's home (notifications).
  static const String notificationsBell = 'notifications-bell';

  /// The widget lent under [name], or null when its feature isn't
  /// registered (e.g. in a test of the borrowing feature alone).
  static Widget? widget(GetIt getIt, String name) =>
      getIt.isRegistered<Widget>(instanceName: name)
      ? getIt<Widget>(instanceName: name)
      : null;
}
