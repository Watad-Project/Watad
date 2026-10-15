import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/datasource/repositories/client_projects_repository_impl.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_by_id_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_tab.dart';

/// Registers everything in lib/features/projects/client/.
void registerClientProjectsDependencies(GetIt getIt) {
  // Datasource
  getIt.registerLazySingleton<ClientProjectsRemoteDataSource>(
    () => ClientProjectsRemoteDataSourceImpl(getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<ClientProjectsRepository>(
    () => ClientProjectsRepositoryImpl(getIt()),
  );

  // Use cases
  getIt.registerLazySingleton<ClientGetMyProjectsUseCase>(
    () => ClientGetMyProjectsUseCase(getIt()),
  );
  getIt.registerLazySingleton<ClientGetProjectByIdUseCase>(
    () => ClientGetProjectByIdUseCase(getIt()),
  );
  getIt.registerLazySingleton<ClientGetProjectOffersUseCase>(
    () => ClientGetProjectOffersUseCase(getIt()),
  );
  getIt.registerLazySingleton<ClientAcceptOfferUseCase>(
    () => ClientAcceptOfferUseCase(getIt()),
  );

  // Blocs
  getIt.registerFactory<ClientProjectsBloc>(() => ClientProjectsBloc(getIt()));
  getIt.registerFactory<ClientProjectOffersBloc>(
    () => ClientProjectOffersBloc(getIt(), getIt(), getIt()),
  );

  // Navigation tab widget
  getIt.registerFactory<Widget>(
    () => ClientProjectsTab(bloc: getIt<ClientProjectsBloc>()),
    instanceName: ClientProjectsRoutes.projectsName,
  );
}
