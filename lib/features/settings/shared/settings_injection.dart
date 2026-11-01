import 'package:get_it/get_it.dart';
import 'package:watad/features/settings/shared/datasource/remote/settings_remote_data_source.dart';
import 'package:watad/features/settings/shared/datasource/repositories/settings_repository_impl.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';
import 'package:watad/features/settings/shared/domain/usecases/delete_account_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/get_settings_overview_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/set_notification_preference_use_case.dart';
import 'package:watad/features/settings/shared/domain/usecases/sign_out_use_case.dart';
import 'package:watad/features/settings/shared/presentation/bloc/settings_bloc.dart';

/// Registers everything in lib/features/settings/shared/.
void registerSettingsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<SettingsRemoteDataSource>(
      () => SettingsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetSettingsOverviewUseCase(getIt()))
    ..registerLazySingleton(() => SetNotificationPreferenceUseCase(getIt()))
    ..registerLazySingleton(() => SignOutUseCase(getIt()))
    ..registerLazySingleton(() => DeleteAccountUseCase(getIt()))
    ..registerFactory(() => SettingsBloc(getIt(), getIt(), getIt(), getIt()));
}
