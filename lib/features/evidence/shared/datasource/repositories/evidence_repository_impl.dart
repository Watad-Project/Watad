import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/evidence/shared/datasource/remote/evidence_remote_data_source.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';
import 'package:watad/features/evidence/shared/domain/repositories/evidence_repository.dart';

class EvidenceRepositoryImpl implements EvidenceRepository {
  const EvidenceRepositoryImpl(this._remote);

  final EvidenceRemoteDataSource _remote;

  @override
  Future<Result<List<EvidenceProject>>> getContractedProjects() =>
      guardSupabaseCall(_remote.getContractedProjects);

  @override
  Future<Result<EvidenceExport>> export(String projectId) =>
      guardSupabaseCall(() => _remote.export(projectId));
}
