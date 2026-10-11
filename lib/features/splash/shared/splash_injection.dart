import 'package:get_it/get_it.dart';
import 'package:watad/features/splash/shared/datasource/local/splash_local_data_source.dart';
import 'package:watad/features/splash/shared/datasource/repositories/splash_repository_impl.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

void registerSplashDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<SplashLocalDataSource>(
      () => const SplashLocalDataSourceImpl(),
    )
    ..registerLazySingleton<SplashRepository>(
      () => SplashRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton(() => GetInitialDestinationUseCase(getIt()))
    ..registerFactory(() => SplashBloc(getIt()));
}
