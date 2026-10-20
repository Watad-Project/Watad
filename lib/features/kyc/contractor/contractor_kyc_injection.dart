import 'package:get_it/get_it.dart';
import 'package:watad/features/kyc/contractor/datasource/remote/contractor_kyc_remote_data_source.dart';
import 'package:watad/features/kyc/contractor/datasource/repositories/contractor_kyc_repository_impl.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_sign_out_use_case.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';

void registerContractorKycDependencies(GetIt getIt) {
  getIt.registerLazySingleton<ContractorKycRemoteDataSource>(
    () => ContractorKycRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ContractorKycRepository>(
    () => ContractorKycRepositoryImpl(getIt<ContractorKycRemoteDataSource>()),
  );

  getIt.registerLazySingleton<ContractorUploadLicenseUseCase>(
    () => ContractorUploadLicenseUseCase(getIt<ContractorKycRepository>()),
  );

  getIt.registerLazySingleton<ContractorSignOutUseCase>(
    () => ContractorSignOutUseCase(getIt<ContractorKycRepository>()),
  );

  getIt.registerFactory<ContractorLicenseBloc>(
    () => ContractorLicenseBloc(
      getIt<ContractorUploadLicenseUseCase>(),
      getIt<ContractorSignOutUseCase>(),
    ),
  );
}
