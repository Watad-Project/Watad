import 'package:get_it/get_it.dart';
import 'package:watad/features/profile/shared/datasource/remote/profile_remote_data_source.dart';
import 'package:watad/features/profile/shared/datasource/repositories/profile_repository_impl.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_overview_use_case.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

/// Registers the types of lib/features/profile/shared/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerProfileDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    )
    // The account tabs «حسابي» and «منشأتي» (GRA-59).
    ..registerLazySingleton(() => GetProfileOverviewUseCase(getIt()))
    ..registerFactory(() => ProfileOverviewBloc(getIt()));
}
