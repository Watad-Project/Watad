import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/router/routes/admin_dashboard_routes.dart';
import 'package:watad/features/dashboard/admin/datasource/remote/admin_dashboard_remote_data_source.dart';
import 'package:watad/features/dashboard/admin/datasource/repositories/admin_dashboard_repository_impl.dart';
import 'package:watad/features/dashboard/admin/domain/repositories/admin_dashboard_repository.dart';
import 'package:watad/features/dashboard/admin/domain/usecases/admin_get_dashboard_stats_use_case.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/widgets/admin_dashboard_tab.dart';

/// Registers everything in lib/features/dashboard/admin/.
void registerAdminDashboardDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminDashboardRemoteDataSource>(
      () => AdminDashboardRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminDashboardRepository>(
      () => AdminDashboardRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetDashboardStatsUseCase(getIt()))
    ..registerFactory(() => AdminDashboardBloc(getIt()))
    // The admin's navigation shows this as its «الرئيسية» tab; the tab reads
    // the numbers each time it shows.
    ..registerFactory<Widget>(
      () => AdminDashboardTab(
        bloc: getIt<AdminDashboardBloc>(),
        bell: AppSlots.widget(getIt, AppSlots.notificationsBell),
      ),
      instanceName: AdminDashboardRoutes.dashboardName,
    );
}
