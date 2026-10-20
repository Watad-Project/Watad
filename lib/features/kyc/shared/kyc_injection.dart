import 'package:get_it/get_it.dart';
import 'package:watad/features/kyc/shared/datasource/remote/kyc_remote_data_source.dart';
import 'package:watad/features/kyc/shared/datasource/repositories/kyc_repository_impl.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/sign_out_kyc_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';

void registerKycDependencies(GetIt getIt) {
  getIt.registerLazySingleton<KycRemoteDataSource>(
    () => KycRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<KycRepository>(
    () => KycRepositoryImpl(getIt<KycRemoteDataSource>()),
  );

  getIt.registerLazySingleton<GetKycDocumentUseCase>(
    () => GetKycDocumentUseCase(getIt<KycRepository>()),
  );

  getIt.registerLazySingleton<WatchKycDocumentUseCase>(
    () => WatchKycDocumentUseCase(getIt<KycRepository>()),
  );

  getIt.registerLazySingleton<SignOutKycUseCase>(
    () => SignOutKycUseCase(getIt<KycRepository>()),
  );

  getIt.registerFactory<KycStatusBloc>(
    () => KycStatusBloc(
      getIt<GetKycDocumentUseCase>(),
      getIt<WatchKycDocumentUseCase>(),
      getIt<SignOutKycUseCase>(),
    ),
  );
}
