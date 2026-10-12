import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/shared/datasource/local/onboarding_local_data_source.dart';
import 'package:watad/features/onboarding/shared/datasource/repositories/onboarding_repository_impl.dart';

class FakeOnboardingLocalDataSource implements OnboardingLocalDataSource {
  FakeOnboardingLocalDataSource({this.error});

  /// Thrown by [setOnboardingSeen] when set.
  final Object? error;

  bool seen = false;

  @override
  Future<void> setOnboardingSeen() async {
    final error = this.error;
    if (error != null) throw error;
    seen = true;
  }
}

void main() {
  test('markOnboardingSeen saves through the local data source', () async {
    final local = FakeOnboardingLocalDataSource();
    final repository = OnboardingRepositoryImpl(local);

    final result = await repository.markOnboardingSeen();

    expect(result, isA<Success<void>>());
    expect(local.seen, isTrue);
  });

  test('markOnboardingSeen returns Failed when saving throws', () async {
    final local = FakeOnboardingLocalDataSource(error: StateError('disk full'));
    final repository = OnboardingRepositoryImpl(local);

    final result = await repository.markOnboardingSeen();

    expect(
      result,
      isA<Failed<void>>().having(
        (failed) => failed.failure,
        'failure',
        isA<UnknownFailure>(),
      ),
    );
  });
}
