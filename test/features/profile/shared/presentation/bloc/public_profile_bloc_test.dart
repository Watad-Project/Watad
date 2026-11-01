import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_reviews_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_public_profile_use_case.dart';
import 'package:watad/features/profile/shared/presentation/bloc/public_profile_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

PublicProfileBloc _bloc(FakeProfileRepository repository) => PublicProfileBloc(
  GetPublicProfileUseCase(repository),
  GetProfileReviewsUseCase(repository),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads the profile', () async {
    final bloc = _bloc(FakeProfileRepository())
      ..add(const PublicProfileFetched('u-1'));
    await _settle();

    expect(bloc.state.status, PublicProfileStatus.success);
    expect(bloc.state.overview?.profile.displayName, 'مؤسسة البناء المتين');
    await bloc.close();
  });

  test('a failed load keeps the failure', () async {
    final repository = FakeProfileRepository()
      ..publicProfileResult = const Failed(NotFoundFailure());
    final bloc = _bloc(repository)..add(const PublicProfileFetched('u-1'));
    await _settle();

    expect(bloc.state.status, PublicProfileStatus.failure);
    expect(bloc.state.failure, isA<NotFoundFailure>());
    expect(bloc.state.overview, isNull);
    await bloc.close();
  });

  test('more reviews are added after the first page', () async {
    final repository = FakeProfileRepository()
      ..reviews = fakeProfileReviews(13);
    final bloc = _bloc(repository)..add(const PublicProfileFetched('u-1'));
    await _settle();

    bloc.add(const PublicProfileMoreReviewsRequested());
    await _settle();

    expect(bloc.state.overview?.reviews, hasLength(13));
    expect(bloc.state.overview?.hasMoreReviews, isFalse);
    expect(repository.calls.last, 'getReviews(u-1, 10)');
    await bloc.close();
  });

  test('a page that fails keeps the reviews and says why', () async {
    final repository = FakeProfileRepository()
      ..reviews = fakeProfileReviews(10);
    final bloc = _bloc(repository)..add(const PublicProfileFetched('u-1'));
    await _settle();
    repository.reviewsResult = const Failed(NetworkFailure());

    bloc.add(const PublicProfileMoreReviewsRequested());
    await _settle();

    expect(bloc.state.overview?.reviews, hasLength(10));
    expect(bloc.state.moreFailure, isA<NetworkFailure>());
    expect(bloc.state.isLoadingMore, isFalse);
    await bloc.close();
  });
}
