part of 'client_task_details_bloc.dart';

sealed class ClientTaskDetailsEvent {
  const ClientTaskDetailsEvent();
}

/// The page opened, or the client tapped retry.
final class ClientTaskDetailsFetched extends ClientTaskDetailsEvent {
  const ClientTaskDetailsFetched({
    required this.projectId,
    required this.taskId,
  });

  final String projectId;
  final String taskId;
}

/// «قبول المهمة», or «رفض المهمة» after the client confirmed.
final class ClientTaskDetailsAnswered extends ClientTaskDetailsEvent {
  const ClientTaskDetailsAnswered(this.status);

  /// `accepted` or `rejected`.
  final TaskStatus status;
}
