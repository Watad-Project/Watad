/// Mirror of the Postgres enum `task_update_state` (ARCHITECTURE.md §4).
enum TaskUpdateState {
  inProgress('in_progress'),
  done('done');

  const TaskUpdateState(this.value);

  final String value;

  static TaskUpdateState fromJson(String value) =>
      values.firstWhere((state) => state.value == value);

  String toJson() => value;
}
