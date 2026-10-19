import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';

import '../../../../../helpers/fake_client_home_repository.dart';

void main() {
  const contractor = ClientSuggestedContractor(
    id: 'c-1',
    companyName: 'البناء المتين',
    ratingAvg: 4.8,
    ratingCount: 64,
  );

  late FakeClientHomeRepository repository;

  ClientHomeBloc buildBloc() => ClientHomeBloc(
    ClientGetHomeProfileUseCase(repository),
    ClientGetSuggestedContractorsUseCase(repository),
  );

  setUp(() => repository = FakeClientHomeRepository());

  test('loads the profile and the contractors', () async {
    repository.contractorsResult = const Success([contractor]);
    final bloc = buildBloc()..add(const ClientHomeStarted());

    final state = await bloc.stream.firstWhere(
      (s) =>
          s.status == ClientHomeStatus.success &&
          s.contractorsStatus == ClientHomeStatus.success,
    );
    expect(state.profile?.fullName, 'عبدالله الحربي');
    expect(state.contractors, [contractor]);
    await bloc.close();
  });

  test('the page fails when the profile cannot load', () async {
    repository.profileResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ClientHomeStarted());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientHomeStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('the contractors fail on their own, and a retry reloads them', () async {
    repository.contractorsResult = const Failed(ServerFailure());
    final bloc = buildBloc()..add(const ClientHomeStarted());

    final failed = await bloc.stream.firstWhere(
      (s) =>
          s.status == ClientHomeStatus.success &&
          s.contractorsStatus == ClientHomeStatus.failure,
    );
    expect(failed.profile, isNotNull);
    expect(failed.contractorsFailure, isA<ServerFailure>());

    repository.contractorsResult = const Success([contractor]);
    bloc.add(const ClientHomeContractorsRetried());
    final retried = await bloc.stream.firstWhere(
      (s) => s.contractorsStatus == ClientHomeStatus.success,
    );
    expect(retried.contractors, [contractor]);
    expect(repository.contractorReads, 2);
    await bloc.close();
  });
}
