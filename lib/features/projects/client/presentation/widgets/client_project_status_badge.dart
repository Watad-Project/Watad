import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/theme/app_tone.dart';

/// A project's status as the client reads it (GRA-24): a draft is
/// «قيد المراجعة» (hidden from contractors), an open project «موثّق».
class ClientProjectStatusBadge extends StatelessWidget {
  const ClientProjectStatusBadge({required this.status, super.key});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final (key, tone) = switch (status) {
      ProjectStatus.draft => ('projects.status_draft', AppTone.attention),
      ProjectStatus.open => ('projects.status_open', AppTone.success),
      ProjectStatus.inProgress => (
        'projects.status_in_progress',
        AppTone.neutral,
      ),
      ProjectStatus.completed => ('projects.status_completed', AppTone.success),
      ProjectStatus.cancelled => ('projects.status_cancelled', AppTone.danger),
    };
    return AppStatusBadge(label: context.tr(key), tone: tone);
  }
}
