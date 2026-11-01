import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';

/// What an export answered: the evidence, or why there's none. The
/// function never answers evidence without the chain's part.
sealed class EvidenceExport {
  const EvidenceExport();
}

final class EvidenceExportReady extends EvidenceExport {
  const EvidenceExportReady(this.evidence);

  final ProjectEvidence evidence;
}

final class EvidenceExportRefused extends EvidenceExport {
  const EvidenceExportRefused(this.refusal);

  final EvidenceRefusal refusal;
}
