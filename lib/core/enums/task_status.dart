/// Mirror of the Postgres enum `task_status` (ARCHITECTURE.md §4).
enum TaskStatus {
  proposed('proposed'),
  accepted('accepted'),
  done('done'),
  approved('approved'),
  rejected('rejected');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus fromJson(String value) =>
      values.firstWhere((status) => status.value == value);

  String toJson() => value;
}
