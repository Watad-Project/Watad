import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_blockchain_routes.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_project_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_page.dart';
import 'package:watad/features/blockchain/admin/presentation/pages/admin_blockchain_project_page.dart';

final List<RouteBase> adminBlockchainRoutes = [
  GoRoute(
    name: AdminBlockchainRoutes.blockchainName,
    path: AdminBlockchainRoutes.blockchainPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminBlockchainBloc>()..add(const AdminBlockchainFetched()),
      child: const AdminBlockchainPage(),
    ),
  ),
  GoRoute(
    name: AdminBlockchainRoutes.blockchainProjectName,
    path: AdminBlockchainRoutes.blockchainProjectPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AdminBlockchainProjectBloc>()
        ..add(
          AdminBlockchainProjectFetched(state.pathParameters['projectId']!),
        ),
      child: const AdminBlockchainProjectPage(),
    ),
  ),
];
