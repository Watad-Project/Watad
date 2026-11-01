/// Mirror of the Postgres enum `notification_group` (ARCHITECTURE.md §4):
/// the groups of notifications a user can mute in settings.
enum NotificationGroup {
  messages('messages'),
  projects('projects'),
  tasks('tasks'),
  marketplace('marketplace');

  const NotificationGroup(this.value);

  /// The exact value stored in Postgres.
  final String value;

  /// Throws on an unknown value: never guess a group.
  static NotificationGroup fromJson(String value) =>
      values.firstWhere((group) => group.value == value);

  String toJson() => value;
}
