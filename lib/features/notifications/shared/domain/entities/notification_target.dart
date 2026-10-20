/// Where a notification leads when tapped: a route name of the app and its
/// path parameters (the row's `data.route` and `data.params`,
/// ARCHITECTURE.md §13).
class NotificationTarget {
  const NotificationTarget({required this.route, this.params = const {}});

  final String route;
  final Map<String, String> params;
}
