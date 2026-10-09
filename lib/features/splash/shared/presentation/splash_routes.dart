import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

final List<RouteBase> splashRoutes = [
  GoRoute(
    name: AppRoutes.splashName,
    path: AppRoutes.splashPath,
    builder: (context, state) => const SplashPage(),
  ),
];
