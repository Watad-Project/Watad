import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/home/client/datasource/remote/client_home_remote_data_source.dart';
import 'package:watad/features/home/client/datasource/repositories/client_home_repository_impl.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_tab.dart';

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
    ..registerFactory(() => ClientHomeBloc(getIt(), getIt()))
    ..registerFactory<Widget>(
      () => ClientHomeTab(
        bloc: getIt<ClientHomeBloc>()..add(const ClientHomeStarted()),
      ),
      instanceName: ClientHomeRoutes.homeName,
    );
}
