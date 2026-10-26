part of 'client_task_update_bloc.dart';

sealed class ClientTaskUpdateEvent {
  const ClientTaskUpdateEvent();
}

/// The page opened, or the client tapped retry.
final class ClientTaskUpdateFetched extends ClientTaskUpdateEvent {
  const ClientTaskUpdateFetched(this.updateId);

  final String updateId;
}

/// «قبول»: the task is approved.
final class ClientTaskUpdateAccepted extends ClientTaskUpdateEvent {
  const ClientTaskUpdateAccepted();
}
