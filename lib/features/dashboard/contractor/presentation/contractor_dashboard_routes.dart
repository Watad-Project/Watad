import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/pages/contractor_dashboard_page.dart';

final List<RouteBase> contractorDashboardRoutes = [
  GoRoute(
    name: ContractorDashboardRoutes.dashboardName,
    path: ContractorDashboardRoutes.dashboardPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ContractorDashboardBloc>()
            ..add(const ContractorDashboardFetched()),
      child: const ContractorDashboardPage(),
    ),
  ),
];
