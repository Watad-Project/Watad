import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/layout/app_section_header.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_job_result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_date.dart';

/// The sync (how many projects are in each state, and the last successful
/// sync) and the retry job (whether it runs, and its last run).
class AdminBlockchainSummarySection extends StatelessWidget {
  const AdminBlockchainSummarySection({required this.summary, super.key});

  final AdminBlockchainSummary summary;

  static String _jobStateKey(bool? isActive) => switch (isActive) {
    true => 'blockchain.admin.job_active',
    false => 'blockchain.admin.job_stopped',
    null => 'blockchain.admin.job_missing',
  };

  static String _jobResultKey(AdminBlockchainJobResult result) =>
      switch (result) {
        AdminBlockchainJobResult.succeeded => 'blockchain.admin.job_succeeded',
        AdminBlockchainJobResult.failed => 'blockchain.admin.job_failed',
        AdminBlockchainJobResult.running => 'blockchain.admin.job_in_progress',
      };

  @override
  Widget build(BuildContext context) {
    final lastResult = summary.retryJobLastResult;
    final lastSyncedAt = summary.lastSyncedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.tr('blockchain.admin.sync'),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
        ),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('blockchain.admin.contracted'),
              value: context.formatNumber(summary.projects),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.status_synced'),
              value: context.formatNumber(summary.synced),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.status_waiting'),
              value: context.formatNumber(summary.waiting),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.status_retrying'),
              value: context.formatNumber(summary.retrying),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.status_failed'),
              value: context.formatNumber(summary.failed),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.last_success'),
              value: lastSyncedAt == null
                  ? context.tr('blockchain.admin.not_yet')
                  : AdminBlockchainDate.format(context, lastSyncedAt),
            ),
          ],
        ),
        AppSectionHeader(
          title: context.tr('blockchain.admin.job'),
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
        ),
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('blockchain.admin.job_state'),
              value: context.tr(_jobStateKey(summary.retryJobActive)),
            ),
            AppKeyValueRow(
              label: context.tr('blockchain.admin.job_last_run'),
              value: AdminBlockchainDate.format(
                context,
                summary.retryJobLastRunAt,
              ),
            ),
            if (lastResult != null)
              AppKeyValueRow(
                label: context.tr('blockchain.admin.job_result'),
                value: context.tr(_jobResultKey(lastResult)),
              ),
          ],
        ),
      ],
    );
  }
}
