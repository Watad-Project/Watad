import 'package:get_it/get_it.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/datasource/repositories/client_projects_repository_impl.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

/// Registers the types of lib/features/projects/client/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerClientProjectsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ClientProjectsRemoteDataSource>(
      () => ClientProjectsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ClientProjectsRepository>(
      () =>
          ClientProjectsRepositoryImpl(getIt<ClientProjectsRemoteDataSource>()),
    )
    ..registerLazySingleton<ClientCreateProjectUseCase>(
      () => ClientCreateProjectUseCase(getIt<ClientProjectsRepository>()),
    )
    ..registerFactory<ClientPostProjectBloc>(() {
      return ClientPostProjectBloc(getIt<ClientCreateProjectUseCase>());
    });
}
