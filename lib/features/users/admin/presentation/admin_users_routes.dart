import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_users_routes.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_user_details_bloc.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_users_bloc.dart';
import 'package:watad/features/users/admin/presentation/pages/admin_user_details_page.dart';
import 'package:watad/features/users/admin/presentation/pages/admin_users_page.dart';

final List<RouteBase> adminUsersRoutes = [
  GoRoute(
    name: AdminUsersRoutes.usersName,
    path: AdminUsersRoutes.usersPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AdminUsersBloc>()..add(const AdminUsersFetched()),
      child: const AdminUsersPage(),
    ),
  ),
  GoRoute(
    name: AdminUsersRoutes.userDetailsName,
    path: AdminUsersRoutes.userDetailsPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<AdminUserDetailsBloc>()
            ..add(AdminUserDetailsFetched(state.pathParameters['userId']!)),
      child: const AdminUserDetailsPage(),
    ),
  ),
];
