import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/home/client/datasource/remote/client_home_remote_data_source.dart';
import 'package:watad/features/home/client/datasource/repositories/client_home_repository_impl.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_contractor_cities_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_contractors_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_contractors_bloc.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_tab.dart';

/// Registers everything in lib/features/home/client/.
void registerClientHomeDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ClientHomeRemoteDataSource>(
      () => ClientHomeRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ClientHomeRepository>(
      () => ClientHomeRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => ClientGetHomeProfileUseCase(getIt()))
    ..registerLazySingleton(() => ClientGetSuggestedContractorsUseCase(getIt()))
    ..registerLazySingleton(() => ClientGetContractorsUseCase(getIt()))
    ..registerLazySingleton(() => ClientGetContractorCitiesUseCase(getIt()))
    ..registerFactory(() => ClientHomeBloc(getIt(), getIt()))
    ..registerFactory(() => ClientContractorsBloc(getIt(), getIt()))
    // The client's navigation shows this as its «الرئيسية» tab.
    ..registerFactory<Widget>(
      () => ClientHomeTab(
        bloc: getIt<ClientHomeBloc>()..add(const ClientHomeStarted()),
        bell: _bell(getIt),
      ),
      instanceName: ClientHomeRoutes.homeName,
    );
}

/// The notifications feature's bell, when it is registered.
Widget? _bell(GetIt getIt) =>
    getIt.isRegistered<Widget>(instanceName: AppSlots.notificationsBell)
    ? getIt<Widget>(instanceName: AppSlots.notificationsBell)
    : null;
