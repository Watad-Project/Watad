import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/datasource/repositories/marketplace_repository_impl.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
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
    ..registerFactory(() => MarketplaceBloc(getIt()))
    ..registerFactory<Widget>(
      () => MarketplaceTab(
        bloc: getIt<MarketplaceBloc>()..add(const MarketplaceFetched()),
      ),
      instanceName: MarketplaceRoutes.marketplaceName,
    );
}
