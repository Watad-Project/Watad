import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_summary.dart';

/// What the monitor shows under the ledger's health: the summary and every
/// contracted project, those that need attention first.
class AdminBlockchainOverview {
  const AdminBlockchainOverview({
    required this.summary,
    required this.projects,
  });

  final AdminBlockchainSummary summary;
  final List<AdminBlockchainProject> projects;
}
