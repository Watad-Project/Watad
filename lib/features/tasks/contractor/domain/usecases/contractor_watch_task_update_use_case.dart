import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_update.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';

/// Subscribes to live changes on a contractor task update via Supabase
/// Realtime (GRA-39).
class ContractorWatchTaskUpdateUseCase
    implements UseCase<Stream<Result<ContractorTaskUpdate>>, String> {
  const ContractorWatchTaskUpdateUseCase(this._repository);

  final ContractorTasksRepository _repository;

  @override
  Future<Result<Stream<Result<ContractorTaskUpdate>>>> call(
    String updateId,
  ) async => Success(_repository.watchTaskUpdate(updateId));
}
