import 'package:get_it/get_it.dart';
import 'package:watad/features/onboarding/contractor/datasource/remote/contractor_onboarding_remote_data_source.dart';
import 'package:watad/features/onboarding/contractor/datasource/repositories/contractor_onboarding_repository_impl.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';
import 'package:watad/features/onboarding/contractor/domain/usecases/contractor_save_specialty_use_case.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';

void registerContractorOnboardingDependencies(GetIt getIt) {
  // Data source
  getIt.registerLazySingleton<ContractorOnboardingRemoteDataSource>(
    () => ContractorOnboardingRemoteDataSourceImpl(getIt()),
  );

  // Repository
  getIt.registerLazySingleton<ContractorOnboardingRepository>(
    () => ContractorOnboardingRepositoryImpl(getIt()),
  );

  // Use case
  getIt.registerLazySingleton<ContractorSaveSpecialtyUseCase>(
    () => ContractorSaveSpecialtyUseCase(getIt()),
  );

  // Bloc (factory: fresh instance per BlocProvider)
  getIt.registerFactory<ContractorSpecialtyBloc>(
    () => ContractorSpecialtyBloc(getIt()),
  );
}
