import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/marketplace/shared/datasource/local/cart_local_data_source.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/orders_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/datasource/repositories/cart_repository_impl.dart';
import 'package:watad/features/marketplace/shared/datasource/repositories/marketplace_repository_impl.dart';
import 'package:watad/features/marketplace/shared/datasource/repositories/orders_repository_impl.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/cart_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/orders_repository.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/add_to_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/cancel_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/check_card_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/confirm_order_delivered_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/create_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/delete_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_count_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_orders_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_details_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/pay_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/place_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/remove_from_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/restore_cart_line_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/review_checkout_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_cart_quantity_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_marketplace_item_active_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/update_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/cart_count_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/checkout_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_item_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_order_details_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_orders_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_item_form_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_items_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/payment_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_tab.dart';

/// Registers everything in lib/features/marketplace/shared/.
void registerMarketplaceDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<MarketplaceRemoteDataSource>(
      () => MarketplaceRemoteDataSourceImpl(getIt()),
    )
    // The cart's key holds the signed-in user's id, read on every call.
    ..registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(
        () => getIt<MarketplaceRemoteDataSource>().currentUserId(),
      ),
    )
    ..registerLazySingleton<MarketplaceRepository>(
      () => MarketplaceRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<OrdersRemoteDataSource>(
      () => OrdersRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<CartRepository>(() => CartRepositoryImpl(getIt()))
    ..registerLazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => GetMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => GetMyMarketplaceItemsUseCase(getIt()))
    ..registerLazySingleton(() => GetMyMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => CreateMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => UpdateMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => SetMarketplaceItemActiveUseCase(getIt()))
    ..registerLazySingleton(() => DeleteMarketplaceItemUseCase(getIt()))
    ..registerLazySingleton(() => AddToCartUseCase(getIt()))
    ..registerLazySingleton(() => GetCartCountUseCase(getIt()))
    ..registerLazySingleton(() => GetCartUseCase(getIt(), getIt()))
    ..registerLazySingleton(() => SetCartQuantityUseCase(getIt()))
    ..registerLazySingleton(() => RemoveFromCartUseCase(getIt()))
    ..registerLazySingleton(() => RestoreCartLineUseCase(getIt()))
    ..registerLazySingleton(
      () => ReviewCheckoutUseCase(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton(() => PlaceOrderUseCase(getIt(), getIt(), getIt()))
    ..registerLazySingleton(CheckCardUseCase.new)
    ..registerLazySingleton(() => PayOrderUseCase(getIt()))
    ..registerLazySingleton(() => GetOrderUseCase(getIt()))
    ..registerLazySingleton(() => GetMyOrdersUseCase(getIt()))
    ..registerLazySingleton(() => GetOrderDetailsUseCase(getIt()))
    ..registerLazySingleton(() => CancelOrderUseCase(getIt()))
    ..registerLazySingleton(() => ConfirmOrderDeliveredUseCase(getIt()))
    ..registerFactory(() => MarketplaceBloc(getIt()))
    ..registerFactory(() => MarketplaceItemBloc(getIt(), getIt()))
    ..registerFactory(() => CartCountBloc(getIt()))
    ..registerFactory(() => CartBloc(getIt(), getIt(), getIt(), getIt()))
    ..registerFactory(() => CheckoutBloc(getIt(), getIt()))
    ..registerFactory(() => PaymentBloc(getIt(), getIt(), getIt()))
    ..registerFactory(() => MarketplaceOrdersBloc(getIt()))
    ..registerFactory(
      () => MarketplaceOrderDetailsBloc(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => MyItemsBloc(getIt(), getIt(), getIt()))
    ..registerFactory(() => MyItemFormBloc(getIt(), getIt(), getIt()))
    ..registerFactory<Widget>(
      () => MarketplaceTab(
        bloc: getIt<MarketplaceBloc>()..add(const MarketplaceFetched()),
        cartCountBloc: getIt<CartCountBloc>()..add(const CartCountRefreshed()),
      ),
      instanceName: MarketplaceRoutes.marketplaceName,
    );

  // Every order notification opens the order, for its buyer and its seller
  // alike (ARCHITECTURE.md §13).
  for (final type in const [
    'order_paid',
    'order_shipped',
    'order_delivered',
    'order_cancelled',
  ]) {
    AppNotificationLinks.register(
      type,
      (data) => (
        name: MarketplaceRoutes.marketplaceOrderDetailsName,
        pathParameters: {'orderId': '${data['order_id']}'},
      ),
    );
  }
}
