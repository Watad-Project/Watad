import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_overview_use_case.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(() => repository = FakeProfileRepository());

  ProfileOverviewBloc buildBloc() =>
      ProfileOverviewBloc(GetProfileOverviewUseCase(repository));

  /// Adds a fetch and waits for the first state that passes [test].
  Future<ProfileOverviewState> fetch(
    ProfileOverviewBloc bloc,
    bool Function(ProfileOverviewState state) test,
  ) {
    final state = bloc.stream.firstWhere(test);
    bloc.add(const ProfileOverviewFetched());
    return state;
  }

  test('emits loading, then the overview', () async {
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream.map((state) => state.status),
      emitsInOrder([
        ProfileOverviewStatus.loading,
        ProfileOverviewStatus.success,
      ]),
    );
    bloc.add(const ProfileOverviewFetched());
    await states;

    expect(bloc.state.overview?.profile.fullName, fakeClientProfile.fullName);
    await bloc.close();
  });

  test('emits loading, then the failure', () async {
    repository.profileResult = const Failed(NetworkFailure());
    final bloc = buildBloc();

    final state = await fetch(
      bloc,
      (s) => s.status == ProfileOverviewStatus.failure,
    );

    expect(state.failure, isA<NetworkFailure>());
    expect(state.overview, isNull);
    await bloc.close();
  });

  test(
    'reloading keeps the profile on screen, then shows the new one',
    () async {
      final bloc = buildBloc();
      await fetch(bloc, (s) => s.status == ProfileOverviewStatus.success);
      repository.profileResult = const Success(
        MyProfile(
          id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
          fullName: 'سارة محمد العتيبي',
          isSuspended: false,
        ),
      );

      final statuses = <ProfileOverviewStatus>[];
      final subscription = bloc.stream.listen((s) => statuses.add(s.status));
      final state = await fetch(
        bloc,
        (s) => s.overview?.profile.fullName == 'سارة محمد العتيبي',
      );

      // No loading state: the old profile stayed until the new one came.
      expect(statuses, [ProfileOverviewStatus.success]);
      expect(state.status, ProfileOverviewStatus.success);
      await subscription.cancel();
      await bloc.close();
    },
  );

  test('a failed reload keeps the profile and reports the failure', () async {
    final bloc = buildBloc();
    await fetch(bloc, (s) => s.status == ProfileOverviewStatus.success);
    repository.profileResult = const Failed(ServerFailure());

    final state = await fetch(
      bloc,
      (s) => s.status == ProfileOverviewStatus.failure,
    );

    expect(state.failure, isA<ServerFailure>());
    expect(state.overview?.profile.fullName, fakeClientProfile.fullName);
    await bloc.close();
  });
}
