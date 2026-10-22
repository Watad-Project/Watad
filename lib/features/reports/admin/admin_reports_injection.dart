import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/features/reports/admin/datasource/remote/admin_reports_remote_data_source.dart';
import 'package:watad/features/reports/admin/datasource/repositories/admin_reports_repository_impl.dart';
import 'package:watad/features/reports/admin/domain/repositories/admin_reports_repository.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_assign_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_close_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_report_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_get_reports_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_remove_reported_listing_use_case.dart';
import 'package:watad/features/reports/admin/domain/usecases/admin_suspend_reported_user_use_case.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_report_details_bloc.dart';
import 'package:watad/features/reports/admin/presentation/bloc/admin_reports_bloc.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_reports_tab.dart';

/// Registers everything in lib/features/reports/admin/.
void registerAdminReportsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminReportsRemoteDataSource>(
      () => AdminReportsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminReportsRepository>(
      () => AdminReportsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetReportsUseCase(getIt()))
    ..registerLazySingleton(() => AdminGetReportUseCase(getIt()))
    ..registerLazySingleton(() => AdminAssignReportUseCase(getIt()))
    ..registerLazySingleton(() => AdminRemoveReportedListingUseCase(getIt()))
    ..registerLazySingleton(() => AdminSuspendReportedUserUseCase(getIt()))
    ..registerLazySingleton(() => AdminCloseReportUseCase(getIt()))
    ..registerFactory(
      () => AdminReportsBloc(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(
      () => AdminReportDetailsBloc(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    // The admin's navigation shows this as its «البلاغات» tab; the tab reads
    // the tickets each time it shows.
    ..registerFactory<Widget>(
      () => AdminReportsTab(
        bloc: getIt<AdminReportsBloc>(),
        bell: AppSlots.widget(getIt, AppSlots.notificationsBell),
      ),
      instanceName: AdminReportsRoutes.reportsName,
    );
}
