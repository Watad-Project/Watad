import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/evidence/shared/domain/usecases/get_contracted_projects_use_case.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_projects_bloc.dart';

import '../../../../../helpers/fake_evidence_repository.dart';

void main() {
  test('emits LoadInProgress then LoadSuccess', () async {
    final bloc = EvidenceProjectsBloc(
      GetContractedProjectsUseCase(FakeEvidenceRepository()),
    );
    final states = bloc.stream.take(2).toList();

    bloc.add(const EvidenceProjectsFetched());

    final emitted = await states;
    expect(emitted.first, isA<EvidenceProjectsLoadInProgress>());
    expect(
      (emitted.last as EvidenceProjectsLoadSuccess).projects.single.id,
      fakeEvidenceProject.id,
    );
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure', () async {
    final repository = FakeEvidenceRepository()
      ..projectsResult = const Failed(NetworkFailure());
    final bloc = EvidenceProjectsBloc(GetContractedProjectsUseCase(repository));
    final states = bloc.stream.take(2).toList();

    bloc.add(const EvidenceProjectsFetched());

    final emitted = await states;
    expect(emitted.first, isA<EvidenceProjectsLoadInProgress>());
    expect(
      (emitted.last as EvidenceProjectsLoadFailure).failure,
      isA<NetworkFailure>(),
    );
    await bloc.close();
  });
}
