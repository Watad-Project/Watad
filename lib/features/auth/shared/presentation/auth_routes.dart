import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_selection_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    name: AppRoutes.loginName,
    path: AppRoutes.loginPath,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    name: AppRoutes.roleSelectionName,
    path: AppRoutes.roleSelectionPath,
    builder: (context, state) => const RoleSelectionPage(),
  ),
  GoRoute(
    name: AppRoutes.signUpClientName,
    path: AppRoutes.signUpClientPath,
    builder: (context, state) => const SignUpClientPage(),
  ),
  GoRoute(
    name: AppRoutes.signUpBusinessName,
    path: AppRoutes.signUpBusinessPath,
    builder: (context, state) => const SignUpBusinessPage(),
  ),
];
