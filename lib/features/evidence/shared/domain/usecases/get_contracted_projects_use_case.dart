import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';
import 'package:watad/features/evidence/shared/domain/repositories/evidence_repository.dart';

class GetContractedProjectsUseCase
    implements UseCase<List<EvidenceProject>, NoParams> {
  const GetContractedProjectsUseCase(this._repository);

  final EvidenceRepository _repository;

  @override
  Future<Result<List<EvidenceProject>>> call(NoParams params) =>
      _repository.getContractedProjects();
}
