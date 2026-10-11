import 'package:get_it/get_it.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/datasource/repositories/auth_repository_impl.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_user_profile_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_sign_up_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';

void registerAuthDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton(() => CheckEmailRegisteredUseCase(getIt()))
    ..registerLazySingleton(() => SendSignUpOtpUseCase(getIt()))
    ..registerLazySingleton(() => VerifySignUpOtpUseCase(getIt()))
    ..registerLazySingleton(() => SaveUserProfileUseCase(getIt()))
    ..registerFactory(
      () => SignUpClientBloc(
        checkEmailRegistered: getIt(),
        sendSignUpOtp: getIt(),
        verifySignUpOtp: getIt(),
        saveUserProfile: getIt(),
      ),
    );
}
