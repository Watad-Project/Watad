import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';

class ProjectEvidenceModel extends ProjectEvidence {
  const ProjectEvidenceModel({
    required super.exportId,
    required super.exportedAt,
    required super.exportedByRole,
    required super.project,
    required super.agreedPrice,
    required super.tasks,
    required super.payments,
    required super.chainFields,
    required super.chainMilestones,
    required super.chainPayments,
    required super.matches,
    required super.fingerprint,
    required super.signature,
    required super.keyId,
    required super.publicKey,
    super.clientName,
    super.contractorCompany,
    super.contractorCrNumber,
    super.lastSyncedAt,
  });

  /// Maps the body of the `project-evidence` Edge Function (ARCHITECTURE.md
  /// §6): the evidence, its comparison and its signature.
  factory ProjectEvidenceModel.fromJson(Map<String, dynamic> json) {
    final evidence = _map(json['evidence']);
    final project = _map(evidence['project']);
    final client = _map(evidence['client']);
    final contractor = _map(evidence['contractor']);
    final sync = _map(evidence['sync']);
    final comparison = _map(json['comparison'] ?? evidence['comparison']);
    return ProjectEvidenceModel(
      exportId: json['export_id'] as String,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      exportedByRole: _map(evidence['exported_by'])['role'] as String? ?? '',
      project: EvidenceProjectDetails(
        title: project['title'] as String? ?? '',
        status: ProjectStatus.fromJson(project['status'] as String),
        city: project['city'] as String? ?? '',
        district: project['district'] as String?,
        description: project['description'] as String?,
        createdAt: DateTime.parse(project['created_at'] as String),
        startedAt: _time(project['started_at']),
        completedAt: _time(project['completed_at']),
      ),
      clientName: client['name'] as String?,
      contractorCompany: contractor['company_name'] as String?,
      contractorCrNumber: contractor['cr_number'] as String?,
      agreedPrice: Money.fromJson(evidence['agreed_price'] as num),
      tasks: [
        for (final task in _list(evidence['tasks']))
          EvidenceTask(
            title: task['title'] as String? ?? '',
            description: task['description'] as String? ?? '',
            status: _enum(TaskStatus.values, task['status'], (s) => s.value),
            amount: _money(task['amount']),
            startDate: _day(task['start_date']),
            finishDate: _day(task['finish_date']),
            lastDecision: _enum(
              TaskUpdateDecision.values,
              _map(task['last_update'])['decision'],
              (d) => d.value,
            ),
          ),
      ],
      payments: [
        for (final payment in _list(evidence['payments']))
          EvidencePayment(
            stageNumber: (payment['stage_number'] as num?)?.toInt() ?? 0,
            amount: Money.fromJson(payment['amount'] as num),
            status: _enum(
              PaymentStatus.values,
              payment['status'],
              (s) => s.value,
            ),
            method: payment['method'] as String?,
            paidAt: _time(payment['paid_at']),
            bankTransferStatus:
                _map(payment['bank_transfer'])['status'] as String?,
          ),
      ],
      chainFields: [
        for (final field in _list(comparison['fields']))
          EvidenceFieldCheck(
            field: field['field'] as String,
            database: _text(field['database']),
            chain: _text(field['chain']),
            matches: field['matches'] as bool? ?? false,
          ),
      ],
      chainMilestones: [
        for (final milestone in _list(comparison['milestones']))
          () {
            final shown = milestone['chain'] is Map
                ? _map(milestone['chain'])
                : _map(milestone['database']);
            return EvidenceMilestoneCheck(
              index: (milestone['index'] as num?)?.toInt() ?? 0,
              description: shown['description'] as String?,
              status: shown['status'] as String?,
              matches: milestone['matches'] as bool? ?? false,
            );
          }(),
      ],
      chainPayments: [
        for (final payment in _list(comparison['payments']))
          () {
            final shown = payment['chain'] is Map
                ? _map(payment['chain'])
                : _map(payment['database']);
            return EvidencePaymentCheck(
              id: payment['id'] as String,
              amount: _money(shown['amount']),
              date: shown['date'] as String?,
              matches: payment['matches'] as bool? ?? false,
              isOnChain: payment['chain'] is Map,
              isInDatabase: payment['database'] is Map,
            );
          }(),
      ],
      matches: comparison['matches'] as bool? ?? false,
      lastSyncedAt: _time(sync['synced_at']),
      fingerprint: json['fingerprint'] as String,
      signature: json['signature'] as String,
      keyId: json['key_id'] as String,
      publicKey: json['public_key'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> _list(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
  ];

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  /// A Riyadh calendar day (`2026-10-06`), kept as UTC midnight.
  static DateTime? _day(Object? value) =>
      value is String ? DateTime.parse('${value}T00:00:00Z') : null;

  static Money? _money(Object? value) =>
      value is num ? Money.fromJson(value) : null;

  /// A value as text: a price or id from the chain may be a number.
  static String? _text(Object? value) => value?.toString();

  /// The enum value whose database value is [value]; null for an unknown
  /// one, so a new status never breaks the whole export.
  static T? _enum<T>(List<T> values, Object? value, String Function(T) of) {
    for (final candidate in values) {
      if (of(candidate) == value) return candidate;
    }
    return null;
  }
}
