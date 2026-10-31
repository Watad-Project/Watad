import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_item_form_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_items_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/edit_my_item_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/my_items_page.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/new_my_item_page.dart';

final List<RouteBase> marketplaceRoutes = [
  GoRoute(
    name: MarketplaceRoutes.marketplaceName,
    path: MarketplaceRoutes.marketplacePath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MarketplaceBloc>()..add(const MarketplaceFetched()),
      child: const MarketplacePage(),
    ),
  ),
  GoRoute(
    name: MarketplaceRoutes.myItemsName,
    path: MarketplaceRoutes.myItemsPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MyItemsBloc>()..add(const MyItemsFetched()),
      child: const MyItemsPage(),
    ),
  ),
  GoRoute(
    name: MarketplaceRoutes.newMyItemName,
    path: MarketplaceRoutes.newMyItemPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MyItemFormBloc>()..add(const MyItemFormStarted()),
      child: const NewMyItemPage(),
    ),
  ),
  GoRoute(
    name: MarketplaceRoutes.editMyItemName,
    path: MarketplaceRoutes.editMyItemPath,
    builder: (context, state) {
      final itemId = state.pathParameters['itemId']!;
      return BlocProvider(
        create: (_) =>
            getIt<MyItemFormBloc>()..add(MyItemFormStarted(itemId: itemId)),
        child: const EditMyItemPage(),
      );
    },
  ),
];
