import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/home/client/presentation/bloc/client_contractors_bloc.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/pages/client_contractors_page.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';

final List<RouteBase> clientHomeRoutes = [
  GoRoute(
    name: ClientHomeRoutes.homeName,
    path: ClientHomeRoutes.homePath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ClientHomeBloc>()..add(const ClientHomeStarted()),
      child: const ClientHomePage(),
    ),
  ),
  GoRoute(
    name: ClientHomeRoutes.contractorsName,
    path: ClientHomeRoutes.contractorsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ClientContractorsBloc>()..add(const ClientContractorsFetched()),
      child: const ClientContractorsPage(),
    ),
  ),
];
