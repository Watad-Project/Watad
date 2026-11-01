import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile_overview.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_public_profile_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  test('reads the profile, the items and the first page of reviews', () async {
    final repository = FakeProfileRepository()
      ..reviews = fakeProfileReviews(12);

    final result = await GetPublicProfileUseCase(repository)('u-1');

    final overview = (result as Success<PublicProfileOverview>).data;
    expect(overview.items, hasLength(2));
    expect(overview.reviews, hasLength(10));
    expect(overview.hasMoreReviews, isTrue);
    expect(repository.calls, [
      'getPublicProfile(u-1)',
      'getMarketItems(u-1)',
      'getReviews(u-1, 0)',
    ]);
  });

  test('fewer reviews than a page means no more', () async {
    final result = await GetPublicProfileUseCase(FakeProfileRepository())('u');

    expect(
      (result as Success<PublicProfileOverview>).data.hasMoreReviews,
      isFalse,
    );
  });

  test('any part failing fails the whole', () async {
    final repository = FakeProfileRepository()
      ..itemsResult = const Failed(NetworkFailure());

    final result = await GetPublicProfileUseCase(repository)('u-1');

    expect((result as Failed).failure, isA<NetworkFailure>());
    expect(repository.calls, isNot(contains('getReviews(u-1, 0)')));
  });
}
