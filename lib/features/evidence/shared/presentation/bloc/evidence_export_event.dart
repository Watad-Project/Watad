part of 'evidence_export_bloc.dart';

sealed class EvidenceExportEvent {
  const EvidenceExportEvent();
}

/// Collect the project's evidence: when the page opens, and on retry.
final class EvidenceExportStarted extends EvidenceExportEvent {
  const EvidenceExportStarted(this.projectId);

  final String projectId;
}
