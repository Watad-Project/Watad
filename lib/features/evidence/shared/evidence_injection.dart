import 'package:get_it/get_it.dart';
import 'package:watad/features/evidence/shared/datasource/remote/evidence_remote_data_source.dart';
import 'package:watad/features/evidence/shared/datasource/repositories/evidence_repository_impl.dart';
import 'package:watad/features/evidence/shared/domain/repositories/evidence_repository.dart';
import 'package:watad/features/evidence/shared/domain/usecases/export_project_evidence_use_case.dart';
import 'package:watad/features/evidence/shared/domain/usecases/get_contracted_projects_use_case.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_export_bloc.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_projects_bloc.dart';

/// Registers everything in lib/features/evidence/shared/.
void registerEvidenceDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<EvidenceRemoteDataSource>(
      () => EvidenceRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<EvidenceRepository>(
      () => EvidenceRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetContractedProjectsUseCase(getIt()))
    ..registerLazySingleton(() => ExportProjectEvidenceUseCase(getIt()))
    ..registerFactory(() => EvidenceProjectsBloc(getIt()))
    ..registerFactory(() => EvidenceExportBloc(getIt()));
}
