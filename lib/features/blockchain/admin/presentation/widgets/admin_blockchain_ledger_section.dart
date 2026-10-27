import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health_problem.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_date.dart';

/// The ledger: «متصل» or «غير متصل», when it was last checked and how long
/// it took to answer, and «فحص الآن».
class AdminBlockchainLedgerSection extends StatelessWidget {
  const AdminBlockchainLedgerSection({
    required this.isChecking,
    required this.onCheck,
    this.health,
    this.failure,
    super.key,
  });

  /// The last check; null until one finished.
  final AdminBlockchainHealth? health;

  /// Why the last check couldn't run at all.
  final Failure? failure;

  final bool isChecking;
  final VoidCallback onCheck;

  static String _problemKey(AdminBlockchainHealthProblem problem) =>
      switch (problem) {
        AdminBlockchainHealthProblem.timeout =>
          'blockchain.admin.problem_timeout',
        AdminBlockchainHealthProblem.unreachable =>
          'blockchain.admin.problem_unreachable',
        AdminBlockchainHealthProblem.badStatus =>
          'blockchain.admin.problem_bad_status',
      };

  @override
  Widget build(BuildContext context) {
    final health = this.health;
    final failure = this.failure;
    final String state;
    if (health == null) {
      state = context.tr(
        isChecking
            ? 'blockchain.admin.ledger_checking'
            : 'blockchain.admin.ledger_check_failed',
      );
    } else {
      state = context.tr(
        health.isReachable
            ? 'blockchain.admin.ledger_connected'
            : 'blockchain.admin.ledger_disconnected',
      );
    }
    final latency = health?.latency;
    final httpStatus = health?.httpStatus;
    final problem = health?.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppKeyValueList(
          rows: [
            AppKeyValueRow(
              label: context.tr('blockchain.admin.ledger_state'),
              value: state,
            ),
            if (health == null && failure != null && !isChecking)
              AppKeyValueRow(
                label: context.tr('blockchain.admin.reason'),
                value: context.tr(failure.messageKey),
              ),
            if (health != null) ...[
              AppKeyValueRow(
                label: context.tr('blockchain.admin.last_checked'),
                value: AdminBlockchainDate.format(context, health.checkedAt),
              ),
              if (latency != null)
                AppKeyValueRow(
                  label: context.tr('blockchain.admin.response_time'),
                  value: context.tr(
                    'blockchain.admin.milliseconds',
                    args: [context.formatNumber(latency.inMilliseconds)],
                  ),
                ),
              if (problem != null)
                AppKeyValueRow(
                  label: context.tr('blockchain.admin.reason'),
                  value: context.tr(_problemKey(problem)),
                ),
              if (httpStatus != null && !health.isReachable)
                AppKeyValueRow(
                  label: context.tr('blockchain.admin.response_code'),
                  value: '$httpStatus',
                  isMonospace: true,
                ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: context.tr('blockchain.admin.check_now'),
          variant: AppButtonVariant.secondary,
          isLoading: isChecking,
          onPressed: isChecking ? null : onCheck,
        ),
      ],
    );
  }
}
