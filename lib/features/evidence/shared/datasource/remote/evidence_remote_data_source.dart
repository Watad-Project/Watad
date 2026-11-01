import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/evidence/shared/datasource/models/evidence_project_model.dart';
import 'package:watad/features/evidence/shared/datasource/models/project_evidence_model.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';

abstract interface class EvidenceRemoteDataSource {
  Future<List<EvidenceProjectModel>> getContractedProjects();

  /// The `project-evidence` answer: the evidence, or why it refused (403,
  /// 404, 409, 502, 504…).
  Future<EvidenceExport> export(String projectId);
}

class EvidenceRemoteDataSourceImpl implements EvidenceRemoteDataSource {
  const EvidenceRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EvidenceProjectModel>> getContractedProjects() async {
    final rows = await _client
        .from('v_my_projects')
        .select(
          'id, title, status, my_role, owner_name, taker_company_name, '
          'agreed_amount, created_at',
        )
        .not('accepted_offer_id', 'is', null)
        .inFilter('status', ['in_progress', 'completed'])
        .order('created_at', ascending: false);
    return rows.map(EvidenceProjectModel.fromJson).toList();
  }

  @override
  Future<EvidenceExport> export(String projectId) => _client.functions
      .invoke('project-evidence', body: {'project_id': projectId})
      .then<EvidenceExport>(
        (response) => EvidenceExportReady(
          ProjectEvidenceModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        ),
        // A refusal is an answer, not a failure: say why.
        onError: (Object error, StackTrace stackTrace) {
          if (error is! FunctionException) {
            Error.throwWithStackTrace(error, stackTrace);
          }
          final details = error.details;
          return EvidenceExportRefused(
            refusalOf(
              details is Map && details['error'] is String
                  ? details['error'] as String
                  : '',
            ),
          );
        },
      );

  /// The function's error codes (ARCHITECTURE.md §6).
  static EvidenceRefusal refusalOf(String error) => switch (error) {
    'not_allowed' || 'unauthorized' => EvidenceRefusal.notAllowed,
    'project_not_found' || 'invalid_body' => EvidenceRefusal.notFound,
    'not_on_chain' => EvidenceRefusal.notOnChain,
    'not_on_chain_yet' => EvidenceRefusal.notOnChainYet,
    'ledger_unavailable' => EvidenceRefusal.ledgerUnavailable,
    'timeout' => EvidenceRefusal.timeout,
    _ => EvidenceRefusal.unavailable,
  };
}
