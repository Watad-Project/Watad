import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/evidence/shared/datasource/remote/evidence_remote_data_source.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';

void main() {
  test("every error of project-evidence maps to why there's no evidence", () {
    expect(
      {
        for (final error in [
          'not_allowed',
          'unauthorized',
          'project_not_found',
          'invalid_body',
          'not_on_chain',
          'not_on_chain_yet',
          'ledger_unavailable',
          'timeout',
          'not_configured',
          '',
        ])
          error: EvidenceRemoteDataSourceImpl.refusalOf(error),
      },
      {
        'not_allowed': EvidenceRefusal.notAllowed,
        'unauthorized': EvidenceRefusal.notAllowed,
        'project_not_found': EvidenceRefusal.notFound,
        'invalid_body': EvidenceRefusal.notFound,
        'not_on_chain': EvidenceRefusal.notOnChain,
        'not_on_chain_yet': EvidenceRefusal.notOnChainYet,
        'ledger_unavailable': EvidenceRefusal.ledgerUnavailable,
        'timeout': EvidenceRefusal.timeout,
        'not_configured': EvidenceRefusal.unavailable,
        '': EvidenceRefusal.unavailable,
      },
    );
  });
}
