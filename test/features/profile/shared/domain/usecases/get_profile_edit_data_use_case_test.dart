import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_edit_data_use_case.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  test('reads the profile, then the identity', () async {
    final result = await GetProfileEditDataUseCase(repository)(
      const NoParams(),
    );

    expect(repository.calls, ['getMyProfile', 'getMyIdentity']);
    switch (result) {
      case Success(:final data):
        expect(data.profile.fullName, fakeClientProfile.fullName);
        expect(data.identity?.nationalId, fakeIdentity.nationalId);
      case Failed():
        fail('Expected the data');
    }
  });

  test('a contractor without a v_my_identity row has no identity', () async {
    repository
      ..profileResult = const Success(fakeContractorProfile)
      ..identityResult = const Success(null);

    final result = await GetProfileEditDataUseCase(repository)(
      const NoParams(),
    );

    switch (result) {
      case Success(:final data):
        expect(data.profile.business, isNotNull);
        expect(data.identity, isNull);
      case Failed():
        fail('Expected the data');
    }
  });

  test('either read failing fails the whole', () async {
    repository.identityResult = const Failed(NetworkFailure());

    final result = await GetProfileEditDataUseCase(repository)(
      const NoParams(),
    );

    switch (result) {
      case Failed(:final failure):
        expect(failure, isA<NetworkFailure>());
      case Success():
        fail('Expected a failure');
    }
  });
}
