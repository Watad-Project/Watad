import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_filter.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overall.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_sync_status.dart';

/// The translation keys and tones of the monitor's states, in one place.
abstract final class AdminBlockchainLabels {
  static String statusKey(AdminBlockchainSyncStatus status) => switch (status) {
    AdminBlockchainSyncStatus.failed => 'blockchain.admin.status_failed',
    AdminBlockchainSyncStatus.retrying => 'blockchain.admin.status_retrying',
    AdminBlockchainSyncStatus.waiting => 'blockchain.admin.status_waiting',
    AdminBlockchainSyncStatus.synced => 'blockchain.admin.status_synced',
  };

  /// Red needs a person, orange is on its way, green is done.
  static AppTone statusTone(AdminBlockchainSyncStatus status) =>
      switch (status) {
        AdminBlockchainSyncStatus.failed => AppTone.danger,
        AdminBlockchainSyncStatus.retrying ||
        AdminBlockchainSyncStatus.waiting => AppTone.attention,
        AdminBlockchainSyncStatus.synced => AppTone.success,
      };

  static String filterKey(AdminBlockchainFilter filter) =>
      switch (filter.status) {
        final status? => statusKey(status),
        null => 'blockchain.admin.filter_all',
      };

  static String overallKey(AdminBlockchainOverall overall) => switch (overall) {
    AdminBlockchainOverall.healthy => 'blockchain.admin.overall_healthy',
    AdminBlockchainOverall.syncing => 'blockchain.admin.overall_syncing',
    AdminBlockchainOverall.attention => 'blockchain.admin.overall_attention',
  };

  static AppTone overallTone(AdminBlockchainOverall overall) =>
      switch (overall) {
        AdminBlockchainOverall.healthy => AppTone.success,
        AdminBlockchainOverall.syncing => AppTone.attention,
        AdminBlockchainOverall.attention => AppTone.danger,
      };
}
