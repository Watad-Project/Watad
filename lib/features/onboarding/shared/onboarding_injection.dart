import 'package:get_it/get_it.dart';
import 'package:watad/features/onboarding/shared/datasource/local/onboarding_local_data_source.dart';
import 'package:watad/features/onboarding/shared/datasource/repositories/onboarding_repository_impl.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';
import 'package:watad/features/onboarding/shared/domain/usecases/mark_onboarding_seen_use_case.dart';
import 'package:watad/features/onboarding/shared/presentation/bloc/onboarding_bloc.dart';

/// Registers everything in lib/features/onboarding/shared/.
void registerOnboardingDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<OnboardingLocalDataSource>(
      () => const OnboardingLocalDataSourceImpl(),
    )
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => MarkOnboardingSeenUseCase(getIt()))
    ..registerFactory(() => OnboardingBloc(getIt()));
}
