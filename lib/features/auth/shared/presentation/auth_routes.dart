import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    name: AuthRoutes.roleName,
    path: AuthRoutes.rolePath,
    builder: (context, state) =>
        BlocProvider(create: (_) => getIt<RoleBloc>(), child: const RolePage()),
  ),
];
