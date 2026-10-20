/// A screen to open: a route name and its path parameters.
typedef AppNotificationLink = ({
  String name,
  Map<String, String> pathParameters,
});

/// Where a notification opens when it's tapped (its toast, its push, its row
/// in the list), by the event in its `data.type` (ARCHITECTURE.md §13).
///
/// The server only says what happened: `data.type` and the ids (e.g.
/// `{"type": "task_added", "project_id": "…", "task_id": "…"}`). The
/// feature that has the screen for that event links it, once, in its
/// injection file:
///
/// ```dart
/// AppNotificationLinks.register(
///   'task_added',
///   (data) => (
///     name: ContractorJobsRoutes.jobName,
///     pathParameters: {'id': '${data['project_id']}'},
///   ),
/// );
/// ```
///
/// A type nothing links (no screen yet) opens the notifications list.
abstract final class AppNotificationLinks {
  static final Map<String, AppNotificationLink? Function(Map<String, Object?>)>
  _links = {};

  /// Links the notifications of [type] to the screen [link] builds from
  /// their data; null from [link] opens nothing for that one.
  static void register(
    String type,
    AppNotificationLink? Function(Map<String, Object?> data) link,
  ) => _links[type] = link;

  /// The screen for a notification's [data], or null when nothing links
  /// its type.
  static AppNotificationLink? linkOf(Map<String, Object?> data) {
    final type = data['type'];
    return type is String ? _links[type]?.call(data) : null;
  }

  /// For tests only: forgets every link.
  static void clear() => _links.clear();
}
