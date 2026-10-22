import 'package:watad/core/enums/project_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

/// The chips of «مشاريعي», in their order on screen.
enum ClientProjectsFilter {
  /// Finished: completed, or cancelled.
  done,

  /// Waiting for the deed's approval (drafts) or for offers (open).
  waiting,

  /// Being built by the contractor whose offer was accepted.
  inProgress;

  bool matches(ClientProject project) => switch (project.status) {
    ProjectStatus.completed || ProjectStatus.cancelled => this == done,
    ProjectStatus.draft || ProjectStatus.open => this == waiting,
    ProjectStatus.inProgress => this == inProgress,
  };
}
