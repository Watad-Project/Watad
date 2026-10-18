import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/features/dashboard/contractor/datasource/remote/contractor_dashboard_remote_data_source.dart';
import 'package:watad/features/dashboard/contractor/datasource/repositories/contractor_dashboard_repository_impl.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/widgets/contractor_dashboard_tab.dart';

void registerContractorDashboardDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ContractorDashboardRemoteDataSource>(
      () => ContractorDashboardRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ContractorDashboardRepository>(
      () => ContractorDashboardRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => ContractorGetDashboardDataUseCase(getIt()))
    ..registerFactory(() => ContractorDashboardBloc(getIt()))
    ..registerFactory<Widget>(
      () => ContractorDashboardTab(
        bloc: getIt<ContractorDashboardBloc>()
          ..add(const ContractorDashboardFetched()),
      ),
      instanceName: ContractorDashboardRoutes.dashboardName,
    );
}
