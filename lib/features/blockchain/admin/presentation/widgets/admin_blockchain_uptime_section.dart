import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_network_state.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_date.dart';

/// The network's uptime (GRA-75), next to the ledger: the share of the last
/// 24 hours' checks that found it healthy («٩٩٫٨٦٪», «٧١٧ من ٧١٨»), the
/// last check, whether it's up now, and whether the monitor runs.
class AdminBlockchainUptimeSection extends StatelessWidget {
  const AdminBlockchainUptimeSection({
    required this.isLoading,
    required this.now,
    this.uptime,
    this.failure,
    super.key,
  });

  /// The last uptime read; null until one finished.
  final AdminBlockchainUptime? uptime;

  /// Why the last read failed.
  final Failure? failure;
  final bool isLoading;

  /// To say whether the last check is recent enough to tell about now.
  final DateTime now;

  static String _networkKey(AdminBlockchainNetworkState state) =>
      switch (state) {
        AdminBlockchainNetworkState.up => 'blockchain.admin.uptime_network_up',
        AdminBlockchainNetworkState.down =>
          'blockchain.admin.uptime_network_down',
        AdminBlockchainNetworkState.unknown =>
          'blockchain.admin.uptime_network_unknown',
      };

  @override
  Widget build(BuildContext context) {
    final uptime = this.uptime;
    final failure = this.failure;
    if (uptime == null) {
      return AppKeyValueList(
        key: const Key('admin_blockchain_uptime'),
        rows: [
          AppKeyValueRow(
            label: context.tr('blockchain.admin.uptime_percent'),
            value: context.tr(
              isLoading || failure == null
                  ? 'blockchain.admin.uptime_loading'
                  : 'blockchain.admin.uptime_failed',
            ),
          ),
          if (failure != null && !isLoading)
            AppKeyValueRow(
              label: context.tr('blockchain.admin.reason'),
              value: context.tr(failure.messageKey),
            ),
        ],
      );
    }
    final percent = uptime.uptimePercent;
    final lastCheckAt = uptime.lastCheckAt;
    return AppKeyValueList(
      key: const Key('admin_blockchain_uptime'),
      rows: [
        AppKeyValueRow(
          label: context.tr('blockchain.admin.uptime_percent'),
          value: percent == null
              ? context.tr('blockchain.admin.uptime_no_checks')
              : context.tr(
                  'blockchain.admin.uptime_percent_value',
                  args: [
                    context.formatNumber(
                      percent,
                      decimals: percent == percent.roundToDouble() ? 0 : 2,
                    ),
                  ],
                ),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.uptime_checks'),
          value: context.tr(
            'blockchain.admin.uptime_checks_value',
            args: [
              context.formatNumber(uptime.healthy),
              context.formatNumber(uptime.checks),
            ],
          ),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.uptime_last_check'),
          value: AdminBlockchainDate.format(context, lastCheckAt),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.uptime_network_now'),
          value: context.tr(_networkKey(uptime.networkAt(now))),
        ),
        AppKeyValueRow(
          label: context.tr('blockchain.admin.uptime_monitor'),
          value: context.tr(
            uptime.isMonitorRunning
                ? 'blockchain.admin.uptime_monitor_running'
                : 'blockchain.admin.uptime_monitor_stopped',
          ),
        ),
      ],
    );
  }
}
