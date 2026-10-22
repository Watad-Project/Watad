import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

/// Sends a new ownership deed for review.
class ClientReplaceDeedUseCase
    implements UseCase<void, ClientReplaceDeedParams> {
  const ClientReplaceDeedUseCase(this._repository);

  final ClientProjectsRepository _repository;

  @override
  Future<Result<void>> call(ClientReplaceDeedParams params) =>
      _repository.replaceDeed(params);
}
