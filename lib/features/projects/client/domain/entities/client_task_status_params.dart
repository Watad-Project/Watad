import 'package:watad/core/enums/task_status.dart';

/// The client's answer to a task the contractor proposed: `accepted` or
/// `rejected`.
class ClientTaskStatusParams {
  const ClientTaskStatusParams({required this.taskId, required this.status});

  final String taskId;
  final TaskStatus status;
}
