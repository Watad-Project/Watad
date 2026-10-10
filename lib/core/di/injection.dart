import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/splash/shared/splash_injection.dart';

/// The app's only service locator. Use it only in *_injection.dart and
/// *_routes.dart files (APP_ARCHITECTURE.md §12).
final GetIt getIt = GetIt.instance;

/// Called once from main(), after Supabase.initialize().
void configureDependencies() {
  // Lazy, so registering never touches Supabase: data sources take the
  // client through their constructor.
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Features: one line per role folder, in alphabetical order.
  registerSplashDependencies(getIt);
}
