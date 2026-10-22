import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_dashboard_routes.dart';
import 'package:watad/features/dashboard/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:watad/features/dashboard/admin/presentation/pages/admin_dashboard_page.dart';

final List<RouteBase> adminDashboardRoutes = [
  GoRoute(
    name: AdminDashboardRoutes.dashboardName,
    path: AdminDashboardRoutes.dashboardPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminDashboardBloc>()..add(const AdminDashboardFetched()),
      child: const AdminDashboardPage(),
    ),
  ),
];
