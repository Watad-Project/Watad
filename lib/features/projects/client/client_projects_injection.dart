import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/datasource/repositories/client_projects_repository_impl.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_address_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_tasks_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_saved_addresses_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_replace_deed_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_tasks_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_tab.dart';

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
    ..registerLazySingleton<ClientGetSavedAddressesUseCase>(
      () => ClientGetSavedAddressesUseCase(getIt<ClientProjectsRepository>()),
    )
    ..registerLazySingleton<ClientCreateAddressUseCase>(
      () => ClientCreateAddressUseCase(getIt<ClientProjectsRepository>()),
    )
    ..registerFactory<ClientPostProjectBloc>(() {
      return ClientPostProjectBloc(
        createProjectUseCase: getIt<ClientCreateProjectUseCase>(),
        getSavedAddressesUseCase: getIt<ClientGetSavedAddressesUseCase>(),
        createAddressUseCase: getIt<ClientCreateAddressUseCase>(),
      );
    })
    // «مشاريعي» and the offers (GRA-24).
    ..registerLazySingleton(() => ClientGetMyProjectsUseCase(getIt()))
    ..registerLazySingleton(() => ClientGetProjectUseCase(getIt()))
    ..registerLazySingleton(() => ClientGetProjectOffersUseCase(getIt()))
    ..registerLazySingleton(() => ClientAcceptOfferUseCase(getIt()))
    ..registerLazySingleton(() => ClientReplaceDeedUseCase(getIt()))
    ..registerFactory(() => ClientProjectsBloc(getIt()))
    ..registerFactory(() => ClientProjectOffersBloc(getIt(), getIt(), getIt()))
    ..registerFactory(() => ClientProjectDeedBloc(getIt(), getIt()))
    // A project's tasks (GRA-47).
    ..registerLazySingleton(() => ClientGetProjectTasksUseCase(getIt()))
    ..registerFactory(() => ClientProjectTasksBloc(getIt(), getIt()))
    // The client's navigation shows this as its «مشاريعي» tab.
    ..registerFactory<Widget>(
      () => ClientProjectsTab(
        bloc: getIt<ClientProjectsBloc>()..add(const ClientProjectsFetched()),
      ),
      instanceName: ClientProjectsRoutes.projectsName,
    );

  // A deed's decision opens its project (ARCHITECTURE.md §13): verified,
  // its offers; rejected, the upload of a new deed.
  AppNotificationLinks.register(
    'deed_verified',
    (data) => (
      name: ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': '${data['project_id']}'},
    ),
  );
  AppNotificationLinks.register(
    'deed_rejected',
    (data) => (
      name: ClientProjectsRoutes.projectDeedName,
      pathParameters: {'projectId': '${data['project_id']}'},
    ),
  );
  // A new offer opens the project's offers (migration 70).
  AppNotificationLinks.register(
    'offer_received',
    (data) => (
      name: ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': '${data['project_id']}'},
    ),
  );
  // A task the contractor added opens the project's tasks (migration 68).
  // Only the client gets it: tasks are proposed by the contractor.
  AppNotificationLinks.register(
    'task_added',
    (data) => (
      name: ClientProjectsRoutes.projectTasksName,
      pathParameters: {'projectId': '${data['project_id']}'},
    ),
  );
}
