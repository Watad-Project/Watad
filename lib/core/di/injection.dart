import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/auth/shared/auth_injection.dart';
import 'package:watad/features/kyc/contractor/contractor_kyc_injection.dart';
import 'package:watad/features/kyc/shared/kyc_injection.dart';
import 'package:watad/features/onboarding/contractor/contractor_onboarding_injection.dart';
import 'package:watad/features/onboarding/shared/onboarding_injection.dart';
import 'package:watad/features/review/admin/admin_review_injection.dart';
import 'package:watad/features/splash/shared/splash_injection.dart';

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
    ..registerLazySingleton<AppSession>(() => SupabaseAppSession(getIt()));

  // Features: one line per role folder, in alphabetical order.
  registerAdminReviewDependencies(getIt);
  registerAuthDependencies(getIt);
  registerContractorKycDependencies(getIt);
  registerContractorOnboardingDependencies(getIt);
  registerKycDependencies(getIt);
  registerOnboardingDependencies(getIt);
  registerSplashDependencies(getIt);
}
