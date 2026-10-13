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
  test('emits LoadInProgress then LoadSuccess when loading succeeds', () async {
    const profile = ClientHomeProfile(
      id: 'user-1',
      fullName: 'Ahmad Al-Mansour',
      isPhoneVerified: true,
    );
    const contractors = [
      ClientSuggestedContractor(id: 'c-1', companyName: 'Binaa Contracting'),
    ];
    final repo = FakeClientHomeRepository(
      profileResult: const Success(profile),
      contractorsResult: const Success(contractors),
    );
    final bloc = ClientHomeBloc(
      ClientGetHomeProfileUseCase(repo),
      ClientGetSuggestedContractorsUseCase(repo),
    );

    final expectedStates = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientHomeLoadInProgress>(),
        isA<ClientHomeLoadSuccess>()
            .having((s) => s.profile.fullName, 'fullName', 'Ahmad Al-Mansour')
            .having((s) => s.contractors.length, 'contractors.length', 1),
      ]),
    );

    bloc.add(const ClientHomeStarted());
    await expectedStates;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure when profile fails', () async {
    final repo = FakeClientHomeRepository(
      profileResult: const Failed(NetworkFailure()),
    );
    final bloc = ClientHomeBloc(
      ClientGetHomeProfileUseCase(repo),
      ClientGetSuggestedContractorsUseCase(repo),
    );

    final expectedStates = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientHomeLoadInProgress>(),
        isA<ClientHomeLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NetworkFailure>(),
        ),
      ]),
    );

    bloc.add(const ClientHomeStarted());
    await expectedStates;
    await bloc.close();
  });

  test('emits LoadSuccess with empty list if contractors fails', () async {
    const profile = ClientHomeProfile(
      id: 'user-2',
      fullName: 'Fatima',
      isPhoneVerified: false,
    );
    final repo = FakeClientHomeRepository(
      profileResult: const Success(profile),
      contractorsResult: const Failed(ServerFailure()),
    );
    final bloc = ClientHomeBloc(
      ClientGetHomeProfileUseCase(repo),
      ClientGetSuggestedContractorsUseCase(repo),
    );

    final expectedStates = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientHomeLoadInProgress>(),
        isA<ClientHomeLoadSuccess>()
            .having((s) => s.profile.id, 'id', 'user-2')
            .having(
              (s) => s.contractors.isEmpty,
              'contractors.isEmpty',
              isTrue,
            ),
      ]),
    );

    bloc.add(const ClientHomeRefreshed());
    await expectedStates;
    await bloc.close();
  });
}
