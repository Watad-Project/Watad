import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';
import 'package:watad/features/evidence/shared/domain/repositories/evidence_repository.dart';

/// The project's signed evidence, or a failure that says, in plain words,
/// why there's none. No evidence without its chain part: a file without it
/// would mislead.
class ExportProjectEvidenceUseCase implements UseCase<ProjectEvidence, String> {
  const ExportProjectEvidenceUseCase(this._repository);

  final EvidenceRepository _repository;

  @override
  Future<Result<ProjectEvidence>> call(String projectId) async {
    final result = await _repository.export(projectId);
    return switch (result) {
      Failed(:final failure) => Failed(failure),
      Success(data: EvidenceExportReady(:final evidence)) => Success(evidence),
      Success(data: EvidenceExportRefused(:final refusal)) => Failed(
        ValidationFailure(messageKeyOf(refusal)),
      ),
    };
  }

  static String messageKeyOf(EvidenceRefusal refusal) => switch (refusal) {
    EvidenceRefusal.notAllowed => 'evidence.error_not_allowed',
    EvidenceRefusal.notFound => 'evidence.error_not_found',
    EvidenceRefusal.notOnChain => 'evidence.error_not_on_chain',
    EvidenceRefusal.notOnChainYet => 'evidence.error_not_on_chain_yet',
    EvidenceRefusal.ledgerUnavailable => 'evidence.error_ledger_unavailable',
    EvidenceRefusal.timeout => 'evidence.error_timeout',
    EvidenceRefusal.unavailable => 'evidence.error_unavailable',
  };
}
