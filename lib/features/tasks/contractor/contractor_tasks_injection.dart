import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/tasks/contractor/datasource/remote/contractor_tasks_remote_data_source.dart';
import 'package:watad/features/tasks/contractor/datasource/repositories/contractor_tasks_repository_impl.dart';
import 'package:watad/features/tasks/contractor/domain/repositories/contractor_tasks_repository.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';

/// Registers the types of lib/features/tasks/contractor/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerContractorTasksDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ContractorTasksRemoteDataSource>(
      () => ContractorTasksRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ContractorTasksRepository>(
      () => ContractorTasksRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => ContractorGetTaskProjectUseCase(getIt()))
    ..registerLazySingleton(() => ContractorGetProjectTasksUseCase(getIt()))
    ..registerFactory(() => ContractorProjectTasksBloc(getIt(), getIt()))
    ..registerFactory(() => ContractorTaskUpdateBloc(getIt(), getIt()))
    ..registerFactory(() => ContractorTaskUpdateStepCubit(initialTaskId: null));

  // Contractor notifications that open the contract's project schedule
  // (ARCHITECTURE.md §13).
  for (final type in const [
    'offer_accepted',
    'task_accepted',
    'task_update_accepted',
    'task_update_rejected',
  ]) {
    AppNotificationLinks.register(
      type,
      (data) => (
        name: ContractorTasksRoutes.projectTasksName,
        pathParameters: {'projectId': '${data['project_id']}'},
      ),
    );
  }
}
