import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_marketplace_routes.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_bloc.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_item_bloc.dart';
import 'package:watad/features/marketplace/admin/presentation/pages/admin_marketplace_item_page.dart';
import 'package:watad/features/marketplace/admin/presentation/pages/admin_marketplace_page.dart';

final List<RouteBase> adminMarketplaceRoutes = [
  GoRoute(
    name: AdminMarketplaceRoutes.marketplaceName,
    path: AdminMarketplaceRoutes.marketplacePath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminMarketplaceBloc>()..add(const AdminMarketplaceFetched()),
      child: const AdminMarketplacePage(),
    ),
  ),
  GoRoute(
    name: AdminMarketplaceRoutes.marketplaceItemName,
    path: AdminMarketplaceRoutes.marketplaceItemPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminMarketplaceItemBloc>()
            ..add(AdminMarketplaceItemFetched(state.pathParameters['itemId']!)),
      child: const AdminMarketplaceItemPage(),
    ),
  ),
];
