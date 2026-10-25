import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/supabase/app_presence.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/auth/shared/auth_injection.dart';
import 'package:watad/features/dashboard/admin/admin_dashboard_injection.dart';
import 'package:watad/features/dashboard/contractor/contractor_dashboard_injection.dart';
import 'package:watad/features/home/client/client_home_injection.dart';
import 'package:watad/features/kyc/contractor/contractor_kyc_injection.dart';
import 'package:watad/features/kyc/shared/kyc_injection.dart';
import 'package:watad/features/location/shared/location_injection.dart';
import 'package:watad/features/marketplace/admin/admin_marketplace_injection.dart';
import 'package:watad/features/notifications/shared/notifications_injection.dart';
import 'package:watad/features/onboarding/contractor/contractor_onboarding_injection.dart';
import 'package:watad/features/onboarding/shared/onboarding_injection.dart';
import 'package:watad/features/projects/client/client_projects_injection.dart';
import 'package:watad/features/reports/admin/admin_reports_injection.dart';
import 'package:watad/features/review/admin/admin_review_injection.dart';
import 'package:watad/features/splash/shared/splash_injection.dart';
import 'package:watad/features/work/contractor/contractor_work_injection.dart';
import 'package:watad/features/users/admin/admin_users_injection.dart';
import 'package:watad/features/work/contractor/contractor_work_injection.dart';

/// The app's only service locator. Use it only in *_injection.dart and
/// *_routes.dart files (APP_ARCHITECTURE.md §12).
final GetIt getIt = GetIt.instance;

/// Called once from main(), after Supabase.initialize().
void configureDependencies() {
  // Lazy, so registering never touches Supabase: data sources take the
  // client through their constructor.
  getIt
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    // Who is signed in, and their role, for the router's guard.
    ..registerLazySingleton<AppSession>(() => SupabaseAppSession(getIt()))
    // Who is online, and when they were last seen (ARCHITECTURE.md §14).
    ..registerLazySingleton<AppPresence>(() => SupabaseAppPresence(getIt()));

  // Features: one line per role folder, in alphabetical order.
  registerAdminDashboardDependencies(getIt);
  registerAdminMarketplaceDependencies(getIt);
  registerAdminReportsDependencies(getIt);
  registerAdminReviewDependencies(getIt);
  registerAdminUsersDependencies(getIt);
  registerAuthDependencies(getIt);
  registerClientHomeDependencies(getIt);
  registerClientProjectsDependencies(getIt);
  registerContractorDashboardDependencies(getIt);
  registerContractorKycDependencies(getIt);
  registerContractorOnboardingDependencies(getIt);
  registerContractorWorkDependencies(getIt);
  registerKycDependencies(getIt);
  registerLocationDependencies(getIt);
  registerNotificationsDependencies(getIt);
  registerOnboardingDependencies(getIt);
  registerSplashDependencies(getIt);
}

/// Called once from main(), after configureDependencies(): the services that
/// run for the whole app, on their own: presence and push.
void startAppServices() {
  getIt<AppPresence>().start();
  startNotificationsPush(getIt);
}
