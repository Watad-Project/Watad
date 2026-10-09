import 'package:go_router/go_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';

final List<RouteBase> onboardingRoutes = [
  GoRoute(
    name: AppRoutes.onboardingName,
    path: AppRoutes.onboardingPath,
    builder: (context, state) => const OnboardingPage(),
  ),
];
