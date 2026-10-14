import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_role.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    name: AuthRoutes.loginName,
    path: AuthRoutes.loginPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const LoginPage(),
    ),
  ),
  GoRoute(
    name: AuthRoutes.roleName,
    path: AuthRoutes.rolePath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<RoleBloc>(),
      child: RolePage(
        onContinue: (context, role) {
          if (role == AuthRole.contractor) {
            context.goNamed(AuthRoutes.signUpBusinessName);
          }
        },
      ),
    ),
  ),
  GoRoute(
    name: AuthRoutes.signUpBusinessName,
    path: AuthRoutes.signUpBusinessPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<BusinessSignUpBloc>(),
      child: const SignUpBusinessPage(),
    ),
  ),
];
