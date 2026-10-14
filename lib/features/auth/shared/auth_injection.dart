import 'package:get_it/get_it.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/datasource/repositories/auth_repository_impl.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';

/// Registers everything in lib/features/auth/shared/.
void registerAuthDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton(() => SaveBusinessSignUpUseCase(getIt()))
    ..registerLazySingleton(() => SendOtpUseCase(getIt()))
    ..registerLazySingleton(() => SendSignUpOtpUseCase(getIt()))
    ..registerLazySingleton(() => VerifyOtpUseCase(getIt()))
    ..registerFactory(() => AuthBloc(getIt(), getIt()))
    ..registerFactory(
      () => BusinessSignUpBloc(
        getIt<SendSignUpOtpUseCase>(),
        getIt<VerifyOtpUseCase>(),
        getIt<SaveBusinessSignUpUseCase>(),
      ),
    )
    ..registerFactory<RoleBloc>(() {
      return RoleBloc();
    });
}
