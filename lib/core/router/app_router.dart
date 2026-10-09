import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/auth/shared/presentation/auth_routes.dart';
import 'package:watad/features/business_verification/contractor/presentation/contractor_business_verification_routes.dart';
import 'package:watad/features/business_verification/shared/presentation/business_verification_routes.dart';
import 'package:watad/features/onboarding/contractor/presentation/contractor_onboarding_routes.dart';
import 'package:watad/features/onboarding/shared/presentation/onboarding_routes.dart';
import 'package:watad/features/splash/shared/presentation/splash_routes.dart';

/// The app's only router, used by `WatadApp`.
final GoRouter appRouter = createAppRouter();

/// Builds the router. The app builds it once ([appRouter]); tests build a
/// fresh one each, so one test's navigation doesn't leak into the next.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    redirect: _guard,
    errorBuilder: (context, state) => Scaffold(
      body: AppNotFoundView(
        onBackToStart: () => context.goNamed(AppRoutes.splashName),
      ),
    ),
    routes: [
      // One line per role folder, sorted by file name.
      ...authRoutes,
      ...businessVerificationRoutes,
      ...contractorBusinessVerificationRoutes,
      ...contractorOnboardingRoutes,
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
