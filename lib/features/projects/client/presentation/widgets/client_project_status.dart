import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

/// A project's status as the client reads it (GRA-24), with its deed:
/// «قيد المراجعة» while an admin checks the deed (hidden from contractors),
/// «مرفوض» when the deed was rejected, «موثّق» once it's verified and the
/// project is open, «منشور» for an open project that needs no deed.
abstract final class ClientProjectStatus {
  /// The translation key of [project]'s status, and its tone.
  static ({String key, AppTone tone}) of(ClientProject project) =>
      switch ((project.status, project.deedStatus)) {
        (ProjectStatus.draft, ClientDeedVerificationStatus.rejected) => (
          key: 'projects.client.status_deed_rejected',
          tone: AppTone.danger,
        ),
        (ProjectStatus.draft, ClientDeedVerificationStatus.underReview) => (
          key: 'projects.client.status_draft',
          tone: AppTone.attention,
        ),
        (ProjectStatus.draft, _) => (
          key: 'projects.client.status_saved',
          tone: AppTone.neutral,
        ),
        (ProjectStatus.open, ClientDeedVerificationStatus.verified) => (
          key: 'projects.client.status_open',
          tone: AppTone.success,
        ),
        (ProjectStatus.open, _) => (
          key: 'projects.client.status_published',
          tone: AppTone.success,
        ),
        (ProjectStatus.inProgress, _) => (
          key: 'projects.client.status_in_progress',
          tone: AppTone.neutral,
        ),
        (ProjectStatus.completed, _) => (
          key: 'projects.client.status_completed',
          tone: AppTone.success,
        ),
        (ProjectStatus.cancelled, _) => (
          key: 'projects.client.status_cancelled',
          tone: AppTone.danger,
        ),
      };
}
