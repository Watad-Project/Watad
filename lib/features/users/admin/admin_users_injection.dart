import 'package:get_it/get_it.dart';
import 'package:watad/features/users/admin/datasource/remote/admin_users_remote_data_source.dart';
import 'package:watad/features/users/admin/datasource/repositories/admin_users_repository_impl.dart';
import 'package:watad/features/users/admin/domain/repositories/admin_users_repository.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_count_users_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_get_users_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_set_user_role_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_suspend_user_use_case.dart';
import 'package:watad/features/users/admin/domain/usecases/admin_unsuspend_user_use_case.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_user_details_bloc.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_users_bloc.dart';

/// Registers everything in lib/features/users/admin/.
void registerAdminUsersDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminUsersRemoteDataSource>(
      () => AdminUsersRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminUsersRepository>(
      () => AdminUsersRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetUsersUseCase(getIt()))
    ..registerLazySingleton(() => AdminCountUsersUseCase(getIt()))
    ..registerLazySingleton(() => AdminGetUserUseCase(getIt()))
    ..registerLazySingleton(() => AdminSuspendUserUseCase(getIt()))
    ..registerLazySingleton(() => AdminUnsuspendUserUseCase(getIt()))
    ..registerLazySingleton(() => AdminSetUserRoleUseCase(getIt()))
    ..registerFactory(() => AdminUsersBloc(getIt(), getIt()))
    ..registerFactory(
      () => AdminUserDetailsBloc(getIt(), getIt(), getIt(), getIt()),
    );
}
