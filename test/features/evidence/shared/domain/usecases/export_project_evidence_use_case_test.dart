import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/domain/usecases/export_project_evidence_use_case.dart';

import '../../../../../helpers/fake_evidence_repository.dart';

void main() {
  test('returns the evidence of the project', () async {
    final repository = FakeEvidenceRepository();

    final result = await ExportProjectEvidenceUseCase(repository)('p1');

    expect(result, isA<Success<Object>>());
    expect(repository.exports, ['p1']);
  });

  test('a refusal is a failure that says why', () async {
    final repository = FakeEvidenceRepository()
      ..exportResult = const Success(
        EvidenceExportRefused(EvidenceRefusal.ledgerUnavailable),
      );

    final result = await ExportProjectEvidenceUseCase(repository)('p1');

    expect(
      (result as Failed).failure.messageKey,
      'evidence.error_ledger_unavailable',
    );
  });

  test('a failed call stays that failure', () async {
    final repository = FakeEvidenceRepository()
      ..exportResult = const Failed(NetworkFailure());

    final result = await ExportProjectEvidenceUseCase(repository)('p1');

    expect((result as Failed).failure, isA<NetworkFailure>());
  });
}
