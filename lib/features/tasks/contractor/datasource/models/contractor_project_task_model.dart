import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';

class ContractorProjectTaskModel extends ContractorProjectTask {
  const ContractorProjectTaskModel({
    required super.id,
    required super.projectId,
    required super.title,
    required super.status,
    required super.createdAt,
    super.description,
    super.amount,
    super.paymentId,
    super.paymentStatus,
    super.startDate,
    super.finishDate,
    super.decidedAt,
    super.lastUpdateId,
    super.lastUpdateProposedState,
    super.lastUpdateDecision,
    super.lastUpdateAt,
    super.hasPendingUpdate,
  });

  /// Maps a row from `v_project_tasks` (`my_role = 'taker'`).
  factory ContractorProjectTaskModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] as num?;
    final paymentStatus = json['payment_status'] as String?;
    final startDate = json['start_date'] as String?;
    final finishDate = json['finish_date'] as String?;
    final decidedAt = json['decided_at'] as String?;
    final lastUpdateProposedState =
        json['last_update_proposed_state'] as String?;
    final lastUpdateDecision = json['last_update_decision'] as String?;
    final lastUpdateAt = json['last_update_at'] as String?;

    return ContractorProjectTaskModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      amount: amount == null ? null : Money.fromJson(amount),
      paymentId: json['payment_id'] as String?,
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.fromJson(paymentStatus),
      startDate: startDate == null ? null : _parseCalendarDay(startDate),
      finishDate: finishDate == null ? null : _parseCalendarDay(finishDate),
      decidedAt: decidedAt == null ? null : DateTime.parse(decidedAt),
      lastUpdateId: json['last_update_id'] as String?,
      lastUpdateProposedState: lastUpdateProposedState == null
          ? null
          : TaskStatus.fromJson(lastUpdateProposedState),
      lastUpdateDecision: lastUpdateDecision == null
          ? null
          : TaskUpdateDecision.fromJson(lastUpdateDecision),
      lastUpdateAt: lastUpdateAt == null ? null : DateTime.parse(lastUpdateAt),
      hasPendingUpdate: json['has_pending_update'] as bool? ?? false,
    );
  }

  /// `date` columns (`YYYY-MM-DD`) are Riyadh calendar days: keep the exact
  /// year/month/day at UTC midnight so time-zone shifts never change the date.
  static DateTime _parseCalendarDay(String value) {
    final d = DateTime.parse(value);
    return DateTime.utc(d.year, d.month, d.day);
  }
}
