/// Mirror of the Postgres enum `task_update_decision` (ARCHITECTURE.md §4).
enum TaskUpdateDecision {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const TaskUpdateDecision(this.value);

  final String value;

  static TaskUpdateDecision fromJson(String value) =>
      values.firstWhere((decision) => decision.value == value);

  String toJson() => value;
}
