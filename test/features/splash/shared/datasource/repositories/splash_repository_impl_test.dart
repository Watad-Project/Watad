import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/splash/shared/datasource/local/splash_local_data_source.dart';
import 'package:watad/features/splash/shared/datasource/repositories/splash_repository_impl.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';

class FakeSplashLocalDataSource implements SplashLocalDataSource {
  FakeSplashLocalDataSource({this.onboardingSeen = false});

  bool onboardingSeen;

  @override
  Future<bool> isOnboardingSeen() async => onboardingSeen;

  @override
  Future<void> setOnboardingSeen() async {
    onboardingSeen = true;
  }
}

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://example.com', 'test-anon-key');
  });

  tearDown(() {
    client.dispose();
  });

  test(
    'returns onboarding when user is not signed in and onboarding not seen',
    () async {
      final local = FakeSplashLocalDataSource(onboardingSeen: false);
      final repository = SplashRepositoryImpl(client, local);

      final result = await repository.determineInitialDestination();

      expect(result, isA<Success<SplashDestination>>());
      expect(
        (result as Success<SplashDestination>).data,
        SplashDestination.onboarding,
      );
    },
  );

  test(
    'returns login when user is not signed in and onboarding was seen',
    () async {
      final local = FakeSplashLocalDataSource(onboardingSeen: true);
      final repository = SplashRepositoryImpl(client, local);

      final result = await repository.determineInitialDestination();

      expect(result, isA<Success<SplashDestination>>());
      expect(
        (result as Success<SplashDestination>).data,
        SplashDestination.login,
      );
    },
  );
}
