part of 'evidence_projects_bloc.dart';

sealed class EvidenceProjectsEvent {
  const EvidenceProjectsEvent();
}

/// Load the list: when the page opens, on retry and pull to refresh.
final class EvidenceProjectsFetched extends EvidenceProjectsEvent {
  const EvidenceProjectsFetched();
}
