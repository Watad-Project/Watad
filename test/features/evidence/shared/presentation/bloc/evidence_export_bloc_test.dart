import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/domain/usecases/export_project_evidence_use_case.dart';
import 'package:watad/features/evidence/shared/presentation/bloc/evidence_export_bloc.dart';

import '../../../../../helpers/fake_evidence_repository.dart';

void main() {
  test('emits LoadInProgress then LoadSuccess', () async {
    final repository = FakeEvidenceRepository();
    final bloc = EvidenceExportBloc(ExportProjectEvidenceUseCase(repository));
    final states = bloc.stream.take(2).toList();

    bloc.add(const EvidenceExportStarted('p1'));

    final emitted = await states;
    expect(emitted.first, isA<EvidenceExportLoadInProgress>());
    expect(
      (emitted.last as EvidenceExportLoadSuccess).evidence.exportId,
      fakeProjectEvidence.exportId,
    );
    expect(repository.exports, ['p1']);
    await bloc.close();
  });

  test(
    'emits LoadInProgress then LoadFailure when the chain is down',
    () async {
      final repository = FakeEvidenceRepository()
        ..exportResult = const Success(
          EvidenceExportRefused(EvidenceRefusal.notOnChainYet),
        );
      final bloc = EvidenceExportBloc(ExportProjectEvidenceUseCase(repository));
      final states = bloc.stream.take(2).toList();

      bloc.add(const EvidenceExportStarted('p1'));

      final emitted = await states;
      expect(emitted.first, isA<EvidenceExportLoadInProgress>());
      expect(
        (emitted.last as EvidenceExportLoadFailure).failure.messageKey,
        'evidence.error_not_on_chain_yet',
      );
      await bloc.close();
    },
  );
}
