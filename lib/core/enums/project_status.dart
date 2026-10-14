/// Mirror of the Postgres enum `project_status` (ARCHITECTURE.md §4).
enum ProjectStatus {
  draft('draft'),
  open('open'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const ProjectStatus(this.value);

  final String value;

  static ProjectStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
