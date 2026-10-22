import 'package:get_it/get_it.dart';
import 'package:watad/features/marketplace/admin/datasource/remote/admin_marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/admin/datasource/repositories/admin_marketplace_repository_impl.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_count_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_remove_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_bloc.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_item_bloc.dart';

/// Registers everything in lib/features/marketplace/admin/.
void registerAdminMarketplaceDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminMarketplaceRemoteDataSource>(
      () => AdminMarketplaceRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminMarketplaceRepository>(
      () => AdminMarketplaceRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => AdminCountMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => AdminGetMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => AdminRemoveMarketplaceItemUseCase(getIt()))
    ..registerFactory(() => AdminMarketplaceBloc(getIt(), getIt()))
    ..registerFactory(() => AdminMarketplaceItemBloc(getIt(), getIt()));
}
