import 'package:watad/core/error/result.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';

abstract interface class EvidenceRepository {
  /// My projects with an accepted offer, in progress or completed, newest
  /// first.
  Future<Result<List<EvidenceProject>>> getContractedProjects();

  /// Collects, signs and records the project's evidence.
  Future<Result<EvidenceExport>> export(String projectId);
}
