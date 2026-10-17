import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';

import '../../../../../helpers/fake_client_home_repository.dart';

void main() {
  group('ClientHomeBloc', () {
    late FakeClientHomeRepository repository;
    late ClientHomeBloc bloc;

    setUp(() {
      repository = FakeClientHomeRepository();
      bloc = ClientHomeBloc(
        ClientGetHomeProfileUseCase(repository),
        ClientGetSuggestedContractorsUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has initial status', () {
      expect(bloc.state.status, ClientHomeStatus.initial);
      expect(bloc.state.profile, isNull);
      expect(bloc.state.suggestedContractors, isEmpty);
    });

    test('emits loading then success when data fetching succeeds', () async {
      const expectedProfile = ClientHomeProfile(
        fullName: 'Mohammed Ali',
        isPhoneVerified: true,
      );
      const expectedContractor = ClientSuggestedContractor(
        id: '1',
        companyName: 'Best Contracting',
        rating: 5.0,
        completedProjectsCount: 20,
        isVerified: true,
      );

      repository.profileResult = const Success(expectedProfile);
      repository.contractorsResult = const Success([expectedContractor]);

      final states = <ClientHomeStatus>[];
      bloc.stream.listen((state) {
        states.add(state.status);
      });

      bloc.add(const ClientHomeStarted());
      await pumpEventQueue();

      expect(states, [ClientHomeStatus.loading, ClientHomeStatus.success]);
      expect(bloc.state.profile?.fullName, 'Mohammed Ali');
      expect(bloc.state.suggestedContractors.length, 1);
    });

    test('emits failure when fetching profile fails', () async {
      repository.profileResult = const Failed(ServerFailure());

      final states = <ClientHomeStatus>[];
      bloc.stream.listen((state) {
        states.add(state.status);
      });

      bloc.add(const ClientHomeStarted());
      await pumpEventQueue();

      expect(states, [ClientHomeStatus.loading, ClientHomeStatus.failure]);
      expect(bloc.state.errorMessageKey, 'errors.server');
    });
  });
}
