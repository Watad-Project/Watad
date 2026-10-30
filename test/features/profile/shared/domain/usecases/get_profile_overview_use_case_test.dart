import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_overview_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(
    () => repository = FakeProfileRepository(
      ratingResult: const Success(ProfileRating(count: 12, average: 4.75)),
    ),
  );

  test('reads the profile, then the rating of that user', () async {
    final result = await GetProfileOverviewUseCase(repository)(
      const NoParams(),
    );

    expect(repository.calls, [
      'getMyProfile',
      'getRating(${fakeClientProfile.id})',
    ]);
    switch (result) {
      case Success(:final data):
        expect(data.profile.fullName, fakeClientProfile.fullName);
        expect(data.rating.average, 4.75);
        expect(data.rating.count, 12);
      case Failed():
        fail('Expected the overview');
    }
  });

  test(
    'a profile that fails to load fails, without reading the rating',
    () async {
      repository.profileResult = const Failed(NetworkFailure());

      final result = await GetProfileOverviewUseCase(repository)(
        const NoParams(),
      );

      expect(result, isA<Failed<Object?>>());
      expect(repository.calls, ['getMyProfile']);
    },
  );

  test('a rating that fails to load fails the whole', () async {
    repository.ratingResult = const Failed(ServerFailure());

    final result = await GetProfileOverviewUseCase(repository)(
      const NoParams(),
    );

    switch (result) {
      case Failed(:final failure):
        expect(failure, isA<ServerFailure>());
      case Success():
        fail('Expected a failure');
    }
  });
}
