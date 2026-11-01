part of 'evidence_projects_bloc.dart';

sealed class EvidenceProjectsState {
  const EvidenceProjectsState();
}

final class EvidenceProjectsInitial extends EvidenceProjectsState {
  const EvidenceProjectsInitial();
}

final class EvidenceProjectsLoadInProgress extends EvidenceProjectsState {
  const EvidenceProjectsLoadInProgress();
}

final class EvidenceProjectsLoadSuccess extends EvidenceProjectsState {
  const EvidenceProjectsLoadSuccess(this.projects);

  /// Newest first.
  final List<EvidenceProject> projects;
}

final class EvidenceProjectsLoadFailure extends EvidenceProjectsState {
  const EvidenceProjectsLoadFailure(this.failure);

  final Failure failure;
}
