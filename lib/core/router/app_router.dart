import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/features/auth/shared/presentation/auth_routes.dart';
import 'package:watad/features/navigation/admin/presentation/admin_navigation_routes.dart';
import 'package:watad/features/navigation/client/presentation/client_navigation_routes.dart';
import 'package:watad/features/navigation/contractor/presentation/contractor_navigation_routes.dart';
import 'package:watad/features/onboarding/shared/presentation/onboarding_routes.dart';
import 'package:watad/features/projects/client/presentation/client_projects_routes.dart';
import 'package:watad/features/splash/shared/presentation/splash_routes.dart';

/// The app's only router, used by `WatadApp`.
final GoRouter appRouter = createAppRouter();

/// Where the app opens, and where "Back to start" on the not-found page
/// leads.
const String appStartPath = SplashRoutes.splashPath;

/// Builds the router. The app builds it once ([appRouter]); tests build a
/// fresh one each, so one test's navigation doesn't leak into the next.
GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? appStartPath,
    redirect: _guard,
    errorBuilder: (context, state) => Scaffold(
      body: AppNotFoundView(onBackToStart: () => context.go(appStartPath)),
    ),
    routes: [
      // One line per role folder, sorted by file name. Each folder's names
      // and paths live in lib/core/router/routes/.
      ...adminNavigationRoutes,
      ...authRoutes,
      ...clientNavigationRoutes,
      ...clientProjectsRoutes,
      ...contractorNavigationRoutes,
      ...onboardingRoutes,
      ...splashRoutes,
    ],
  );
}

/// The one place for redirects: the sign-in and role guards. Features never
/// add their own (APP_ARCHITECTURE.md §11).
///
/// Every route is open for now. The auth issues fill this in from the
/// session: signed out goes to login, a role without access goes to its
/// own home. Return a path to redirect, or null to let the navigation
/// through.
String? _guard(BuildContext context, GoRouterState state) => null;
