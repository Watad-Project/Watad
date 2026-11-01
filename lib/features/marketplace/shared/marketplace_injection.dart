import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/datasource/repositories/marketplace_repository_impl.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/create_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/delete_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_marketplace_item_active_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/update_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_item_form_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_items_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_tab.dart';

/// Registers everything in lib/features/marketplace/shared/.
void registerMarketplaceDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<MarketplaceRemoteDataSource>(
      () => MarketplaceRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<MarketplaceRepository>(
      () => MarketplaceRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => GetMyMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => GetMyMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => CreateMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => UpdateMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => SetMarketplaceItemActiveUseCase(getIt()))
    ..registerLazySingleton(() => DeleteMarketplaceItemUseCase(getIt()))
    ..registerFactory(() => MarketplaceBloc(getIt()))
    ..registerFactory(() => MyItemsBloc(getIt(), getIt(), getIt()))
    ..registerFactory(() => MyItemFormBloc(getIt(), getIt(), getIt()))
    ..registerFactory<Widget>(
      () => MarketplaceTab(
        bloc: getIt<MarketplaceBloc>()..add(const MarketplaceFetched()),
      ),
      instanceName: MarketplaceRoutes.marketplaceName,
    );
}
