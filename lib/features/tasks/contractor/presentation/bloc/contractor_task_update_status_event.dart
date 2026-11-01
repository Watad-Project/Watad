part of 'contractor_task_update_status_bloc.dart';

sealed class ContractorTaskUpdateStatusEvent {
  const ContractorTaskUpdateStatusEvent();
}

/// Loads the task update [updateId] and subscribes to live Realtime changes.
final class ContractorTaskUpdateStatusStarted
    extends ContractorTaskUpdateStatusEvent {
  const ContractorTaskUpdateStatusStarted(this.updateId);

  final String updateId;
}

/// Reloads the task update [updateId] (e.g. on retry or pull-to-refresh).
final class ContractorTaskUpdateStatusRefreshed
    extends ContractorTaskUpdateStatusEvent {
  const ContractorTaskUpdateStatusRefreshed(this.updateId);

  final String updateId;
}

final class _ContractorTaskUpdateStatusChanged
    extends ContractorTaskUpdateStatusEvent {
  const _ContractorTaskUpdateStatusChanged(this.update);

  final ContractorTaskUpdate update;
}
