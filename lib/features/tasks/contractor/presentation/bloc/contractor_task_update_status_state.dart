part of 'contractor_task_update_status_bloc.dart';

enum ContractorTaskUpdateStatusStatus { initial, loading, success, failure }

final class ContractorTaskUpdateStatusState {
  const ContractorTaskUpdateStatusState({
    this.status = ContractorTaskUpdateStatusStatus.initial,
    this.update,
    this.failure,
  });

  final ContractorTaskUpdateStatusStatus status;
  final ContractorTaskUpdate? update;
  final Failure? failure;

  ContractorTaskUpdateStatusState copyWith({
    ContractorTaskUpdateStatusStatus? status,
    ContractorTaskUpdate? update,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ContractorTaskUpdateStatusState(
      status: status ?? this.status,
      update: update ?? this.update,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
