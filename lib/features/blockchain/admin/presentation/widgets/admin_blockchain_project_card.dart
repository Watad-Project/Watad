// intl (re-exported by easy_localization) has its own TextDirection.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_date.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_labels.dart';

/// One contracted project in the monitor: its title and status, the client
/// and the contractor, the last sync and the attempts, and for a project
/// that retries or needs attention, the start of the last error.
class AdminBlockchainProjectCard extends StatelessWidget {
  const AdminBlockchainProjectCard({
    required this.project,
    this.onTap,
    super.key,
  });

  final AdminBlockchainProject project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final noName = context.tr('blockchain.admin.no_name');
    final secondary = AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
    );
    final syncedAt = project.syncedAt;
    final message = project.lastMessage;
    final showsError =
        message != null &&
        (project.syncStatus == AdminBlockchainSyncStatus.failed ||
            project.syncStatus == AdminBlockchainSyncStatus.retrying);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: AppStatusBadge(
                  label: context.tr(
                    AdminBlockchainLabels.statusKey(project.syncStatus),
                  ),
                  tone: AdminBlockchainLabels.statusTone(project.syncStatus),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              'blockchain.admin.client_line',
              args: [project.ownerName ?? noName],
            ),
            style: secondary,
          ),
          Text(
            context.tr(
              'blockchain.admin.contractor_line',
              args: [project.contractorName ?? noName],
            ),
            style: secondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              'blockchain.admin.meta_join',
              args: [
                if (syncedAt == null)
                  context.tr('blockchain.admin.never_synced')
                else
                  context.tr(
                    'blockchain.admin.last_sync_line',
                    args: [AdminBlockchainDate.format(context, syncedAt)],
                  ),
                context.tr(
                  'blockchain.admin.attempts_line',
                  args: [context.formatNumber(project.attempts)],
                ),
              ],
            ),
            style: secondary,
          ),
          if (showsError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              // The sync writes its messages in English.
              textDirection: TextDirection.ltr,
              style: AppTextStyles.caption.copyWith(
                color: AdminBlockchainLabels.statusTone(project.syncStatus)
                    .foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
