import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// Accepts a pending update: the task is approved, and a task with an
/// amount gets its payment stage. The parameter is the update's id.
class ClientAcceptTaskUpdateUseCase implements UseCase<void, String> {
  const ClientAcceptTaskUpdateUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.acceptTaskUpdate(params);
}
