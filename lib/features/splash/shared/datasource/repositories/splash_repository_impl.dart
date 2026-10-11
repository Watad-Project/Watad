import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/splash/shared/datasource/local/splash_local_data_source.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';

class SplashRepositoryImpl implements SplashRepository {
  const SplashRepositoryImpl(this._client, this._localDataSource);

  final SupabaseClient _client;
  final SplashLocalDataSource _localDataSource;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() {
    return guardSupabaseCall(() async {
      final session = _client.auth.currentSession;
      if (session != null) {
        return SplashDestination.home;
      }
      final seen = await _localDataSource.isOnboardingSeen();
      if (!seen) {
        return SplashDestination.onboarding;
      }
      return SplashDestination.login;
    });
  }
}
