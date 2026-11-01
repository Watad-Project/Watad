part of 'evidence_export_bloc.dart';

sealed class EvidenceExportState {
  const EvidenceExportState();
}

final class EvidenceExportInitial extends EvidenceExportState {
  const EvidenceExportInitial();
}

/// The server is reading the chain: it can take a few seconds.
final class EvidenceExportLoadInProgress extends EvidenceExportState {
  const EvidenceExportLoadInProgress();
}

final class EvidenceExportLoadSuccess extends EvidenceExportState {
  const EvidenceExportLoadSuccess(this.evidence);

  final ProjectEvidence evidence;
}

/// No evidence: why, in plain words ([Failure.messageKey]).
final class EvidenceExportLoadFailure extends EvidenceExportState {
  const EvidenceExportLoadFailure(this.failure);

  final Failure failure;
}
