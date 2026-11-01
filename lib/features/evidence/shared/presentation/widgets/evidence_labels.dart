import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/theme/app_tone.dart';

/// The translation keys of the statuses and fields shown on the evidence
/// pages and in its PDF.
abstract final class EvidenceLabels {
  static String projectStatusKey(ProjectStatus status) => switch (status) {
    ProjectStatus.draft => 'evidence.project_status_draft',
    ProjectStatus.open => 'evidence.project_status_open',
    ProjectStatus.inProgress => 'evidence.project_status_in_progress',
    ProjectStatus.completed => 'evidence.project_status_completed',
    ProjectStatus.cancelled => 'evidence.project_status_cancelled',
  };

  static AppTone projectStatusTone(ProjectStatus status) => switch (status) {
    ProjectStatus.completed => AppTone.success,
    ProjectStatus.inProgress => AppTone.attention,
    ProjectStatus.cancelled => AppTone.danger,
    ProjectStatus.draft || ProjectStatus.open => AppTone.neutral,
  };

  static String taskStatusKey(TaskStatus? status) => switch (status) {
    TaskStatus.proposed => 'evidence.task_status_proposed',
    TaskStatus.accepted => 'evidence.task_status_accepted',
    TaskStatus.done => 'evidence.task_status_done',
    TaskStatus.approved => 'evidence.task_status_approved',
    TaskStatus.rejected => 'evidence.task_status_rejected',
    null => 'evidence.none',
  };

  static String decisionKey(TaskUpdateDecision? decision) => switch (decision) {
    TaskUpdateDecision.pending => 'evidence.decision_pending',
    TaskUpdateDecision.accepted => 'evidence.decision_accepted',
    TaskUpdateDecision.rejected => 'evidence.decision_rejected',
    null => 'evidence.none',
  };

  static String paymentStatusKey(PaymentStatus? status) => switch (status) {
    PaymentStatus.pending => 'evidence.payment_status_pending',
    PaymentStatus.processing => 'evidence.payment_status_processing',
    PaymentStatus.paid => 'evidence.payment_status_paid',
    PaymentStatus.failed => 'evidence.payment_status_failed',
    PaymentStatus.refunded => 'evidence.payment_status_refunded',
    PaymentStatus.cancelled => 'evidence.payment_status_cancelled',
    null => 'evidence.none',
  };

  /// `gateway`, `wallet` or `bank_transfer`.
  static String methodKey(String? method) => switch (method) {
    'gateway' => 'evidence.method_gateway',
    'wallet' => 'evidence.method_wallet',
    'bank_transfer' => 'evidence.method_bank_transfer',
    _ => 'evidence.none',
  };

  /// The bank transfer receipt's status.
  static String receiptKey(String? status) => switch (status) {
    'pending' => 'evidence.receipt_pending',
    'confirmed' => 'evidence.receipt_confirmed',
    'rejected' => 'evidence.receipt_rejected',
    'cancelled' => 'evidence.receipt_cancelled',
    _ => 'evidence.none',
  };

  /// Who exported: `owner`, `taker` or `admin`.
  static String roleKey(String role) => switch (role) {
    'owner' => 'evidence.role_owner',
    'taker' => 'evidence.role_taker',
    'admin' => 'evidence.role_admin',
    _ => 'evidence.none',
  };

  /// A field of the on-chain record.
  static String fieldKey(String field) => switch (field) {
    'owner' => 'evidence.field_owner',
    'ownerId' => 'evidence.field_owner_id',
    'ownerEmail' => 'evidence.field_owner_email',
    'contractor' => 'evidence.field_contractor',
    'contractorId' => 'evidence.field_contractor_id',
    'contractorEmail' => 'evidence.field_contractor_email',
    'agreedPrice' => 'evidence.field_agreed_price',
    'currency' => 'evidence.field_currency',
    _ => 'evidence.field_other',
  };

  /// The chain's milestone status (the task's status, as the sync writes
  /// it).
  static String milestoneStatusKey(String? status) => switch (status) {
    'proposed' => 'evidence.task_status_proposed',
    'accepted' => 'evidence.task_status_accepted',
    'done' => 'evidence.task_status_done',
    'approved' => 'evidence.task_status_approved',
    'rejected' => 'evidence.task_status_rejected',
    _ => 'evidence.none',
  };
}
