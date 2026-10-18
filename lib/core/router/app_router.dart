import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/auth/shared/presentation/auth_routes.dart';
import 'package:watad/features/kyc/contractor/presentation/contractor_kyc_routes.dart';
import 'package:watad/features/kyc/shared/presentation/kyc_routes.dart';
import 'package:watad/features/navigation/admin/presentation/admin_navigation_routes.dart';
import 'package:watad/features/navigation/client/presentation/client_navigation_routes.dart';
import 'package:watad/features/navigation/contractor/presentation/contractor_navigation_routes.dart';
import 'package:watad/features/onboarding/contractor/presentation/contractor_onboarding_routes.dart';
import 'package:watad/features/onboarding/shared/presentation/onboarding_routes.dart';
import 'package:watad/features/splash/shared/presentation/splash_routes.dart';

/// The app's only router, used by `WatadApp`.
final GoRouter appRouter = createAppRouter(session: getIt<AppSession>());

/// Where the app opens, and where "Back to start" on the not-found page
/// leads.
const String appStartPath = SplashRoutes.splashPath;

/// Builds the router. The app builds it once ([appRouter]); tests build a
/// fresh one each, so one test's navigation doesn't leak into the next.
///
/// The guard runs again whenever [session] changes, e.g. when the login
/// page's code is verified.
GoRouter createAppRouter({
  required AppSession session,
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? appStartPath,
    refreshListenable: session,
    redirect: (context, state) => _guard(session, state),
    errorBuilder: (context, state) => Scaffold(
      body: AppNotFoundView(onBackToStart: () => context.go(appStartPath)),
    ),
    routes: [
      // One line per role folder, sorted by file name. Each folder's names
      // and paths live in lib/core/router/routes/.
      ...adminNavigationRoutes,
      ...authRoutes,
      ...clientNavigationRoutes,
      ...contractorKycRoutes,
      ...contractorNavigationRoutes,
      ...contractorOnboardingRoutes,
      ...kycRoutes,
      ...onboardingRoutes,
      ...splashRoutes,
    ],
  );
}

/// The one place for redirects: the sign-in and role guards. Features never
/// add their own (APP_ARCHITECTURE.md §11).
///
/// - A signed-in user on the login page goes to their role's navigation:
///   right after the code is verified, and when the splash finds a session.
/// - A role's navigation is only for that role: signed out goes to the login
///   page, another role goes to its own navigation.
/// - A signed-in contractor on the KYC status page goes to their navigation
///   if already verified.
///
/// Everything else is open. Returns a path to redirect to, or null to let the
/// navigation through.
FutureOr<String?> _guard(AppSession session, GoRouterState state) {
  final location = state.matchedLocation;
  final isNavigation = _navigationPaths.containsValue(location);
  final isKycStatus = location == KycRoutes.statusPath;
  // Answered right away, so most navigations finish in the same frame. Only
  // reading the role waits.
  if (location != AuthRoutes.loginPath && !isNavigation && !isKycStatus) {
    return null;
  }
  if (!session.isSignedIn) return isNavigation ? AuthRoutes.loginPath : null;
  return _homeOf(session, location);
}

/// The signed-in user's navigation, or null when [location] is already it.
Future<String?> _homeOf(AppSession session, String location) async {
  final AppRole role;
  try {
    role = await session.role();
  } on Object {
    // The role couldn't be read (e.g. offline): stay, and try again on the
    // next navigation.
    return null;
  }
  String home;
  if (role == AppRole.contractor) {
    try {
      home = await session.contractorDestination();
    } on Object {
      home = _navigationPaths[role]!;
    }
  } else {
    home = _navigationPaths[role]!;
  }
  return location == home ? null : home;
}

/// The navigation of each role: where its users land after signing in.
const Map<AppRole, String> _navigationPaths = {
  AppRole.client: ClientNavigationRoutes.navigationPath,
  AppRole.contractor: ContractorNavigationRoutes.navigationPath,
  AppRole.admin: AdminNavigationRoutes.navigationPath,
};
