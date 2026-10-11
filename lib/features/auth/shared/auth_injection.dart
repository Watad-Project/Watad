import 'package:get_it/get_it.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/datasource/repositories/auth_repository_impl.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';

void registerAuthDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton(() => CheckEmailRegisteredUseCase(getIt()))
    ..registerLazySingleton(() => SaveBusinessSignUpUseCase(getIt()))
    ..registerFactory(() => BusinessSignUpBloc(getIt(), getIt()));
}
