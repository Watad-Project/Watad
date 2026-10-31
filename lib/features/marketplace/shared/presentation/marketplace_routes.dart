import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/marketplace_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/pages/marketplace_page.dart';

final List<RouteBase> marketplaceRoutes = [
  GoRoute(
    name: MarketplaceRoutes.marketplaceName,
    path: MarketplaceRoutes.marketplacePath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<MarketplaceBloc>()..add(const MarketplaceFetched()),
      child: const MarketplacePage(),
    ),
  ),
];
