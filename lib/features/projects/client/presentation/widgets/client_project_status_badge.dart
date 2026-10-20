import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';

/// A project's status as the client reads it (GRA-24), with its deed:
/// «قيد المراجعة» while an admin checks the deed (hidden from contractors),
/// «مرفوض» when the deed was rejected, «موثّق» once it's verified and the
/// project is open, «منشور» for an open project that needs no deed.
class ClientProjectStatusBadge extends StatelessWidget {
  const ClientProjectStatusBadge({required this.project, super.key});

  final ClientProject project;

  @override
  Widget build(BuildContext context) {
    final (key, tone) = switch ((project.status, project.deedStatus)) {
      (ProjectStatus.draft, ClientDeedVerificationStatus.rejected) => (
        'projects.client.status_deed_rejected',
        AppTone.danger,
      ),
      (ProjectStatus.draft, ClientDeedVerificationStatus.underReview) => (
        'projects.client.status_draft',
        AppTone.attention,
      ),
      (ProjectStatus.draft, _) => (
        'projects.client.status_saved',
        AppTone.neutral,
      ),
      (ProjectStatus.open, ClientDeedVerificationStatus.verified) => (
        'projects.client.status_open',
        AppTone.success,
      ),
      (ProjectStatus.open, _) => (
        'projects.client.status_published',
        AppTone.success,
      ),
      (ProjectStatus.inProgress, _) => (
        'projects.client.status_in_progress',
        AppTone.neutral,
      ),
      (ProjectStatus.completed, _) => (
        'projects.client.status_completed',
        AppTone.success,
      ),
      (ProjectStatus.cancelled, _) => (
        'projects.client.status_cancelled',
        AppTone.danger,
      ),
    };
    return AppStatusBadge(label: context.tr(key), tone: tone);
  }
}
