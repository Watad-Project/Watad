import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// One update the contractor sent, with its photos and the contractor; the
/// parameter is its id.
class ClientGetTaskUpdateUseCase implements UseCase<ClientTaskUpdate, String> {
  const ClientGetTaskUpdateUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<ClientTaskUpdate>> call(String params) =>
      _repository.getTaskUpdate(params);
}
