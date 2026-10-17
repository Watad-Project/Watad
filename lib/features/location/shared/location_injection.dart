import 'package:get_it/get_it.dart';
import 'package:watad/features/location/shared/datasource/remote/location_remote_data_source.dart';
import 'package:watad/features/location/shared/datasource/repositories/location_repository_impl.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';
import 'package:watad/features/location/shared/domain/usecases/get_saved_addresses_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/save_address_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';

/// Registers dependencies for lib/features/location/shared/.
void registerLocationDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<LocationRemoteDataSource>(
      () => LocationRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetSavedAddressesUseCase(getIt()))
    ..registerLazySingleton(() => SaveAddressUseCase(getIt()))
    ..registerFactory(() => LocationBloc(getIt()));
}
