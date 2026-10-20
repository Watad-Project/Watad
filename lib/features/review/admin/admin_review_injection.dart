import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/features/review/admin/datasource/remote/admin_review_remote_data_source.dart';
import 'package:watad/features/review/admin/datasource/repositories/admin_review_repository_impl.dart';
import 'package:watad/features/review/admin/domain/repositories/admin_review_repository.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_approve_request_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_pending_requests_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_request_details_use_case.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_reject_request_use_case.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_bloc.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_details_bloc.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_tab.dart';

/// Registers everything in lib/features/review/admin/.
void registerAdminReviewDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminReviewRemoteDataSource>(
      () => AdminReviewRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminReviewRepository>(
      () => AdminReviewRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetPendingRequestsUseCase(getIt()))
    ..registerLazySingleton(() => AdminGetRequestDetailsUseCase(getIt()))
    ..registerLazySingleton(() => AdminApproveRequestUseCase(getIt()))
    ..registerLazySingleton(() => AdminRejectRequestUseCase(getIt()))
    ..registerFactory(() => AdminReviewBloc(getIt()))
    ..registerFactory(() => AdminReviewDetailsBloc(getIt(), getIt(), getIt()))
    // The admin's navigation shows this as its «التوثيق» tab.
    ..registerFactory<Widget>(
      () => AdminReviewTab(
        bloc: getIt<AdminReviewBloc>()..add(const AdminReviewFetched()),
        bell: AppSlots.widget(getIt, AppSlots.notificationsBell),
      ),
      instanceName: AdminReviewRoutes.reviewName,
    );
}
