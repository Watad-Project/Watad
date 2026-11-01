import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/utils/money.dart';

/// A project's signed evidence: what the `project-evidence` Edge Function
/// returns (ARCHITECTURE.md §6): the project from the database, its record
/// on the blockchain, how the two compare, and Watad's signature.
class ProjectEvidence {
  const ProjectEvidence({
    required this.exportId,
    required this.exportedAt,
    required this.exportedByRole,
    required this.project,
    required this.agreedPrice,
    required this.tasks,
    required this.payments,
    required this.chainFields,
    required this.chainMilestones,
    required this.chainPayments,
    required this.matches,
    required this.fingerprint,
    required this.signature,
    required this.keyId,
    required this.publicKey,
    this.clientName,
    this.contractorCompany,
    this.contractorCrNumber,
    this.lastSyncedAt,
  });

  final String exportId;
  final DateTime exportedAt;

  /// Who exported it: `owner`, `taker` or `admin`.
  final String exportedByRole;

  final EvidenceProjectDetails project;
  final String? clientName;
  final String? contractorCompany;
  final String? contractorCrNumber;
  final Money agreedPrice;
  final List<EvidenceTask> tasks;
  final List<EvidencePayment> payments;

  /// The on-chain record, compared with the database.
  final List<EvidenceFieldCheck> chainFields;
  final List<EvidenceMilestoneCheck> chainMilestones;
  final List<EvidencePaymentCheck> chainPayments;

  /// Everything on the chain matches the database.
  final bool matches;

  /// The last successful sync to the chain.
  final DateTime? lastSyncedAt;

  /// SHA-256 of the evidence (hex), Watad's Ed25519 signature (base64), the
  /// key's name and its public half (base64url).
  final String fingerprint;
  final String signature;
  final String keyId;
  final String publicKey;
}

class EvidenceProjectDetails {
  const EvidenceProjectDetails({
    required this.title,
    required this.status,
    required this.city,
    required this.createdAt,
    this.description,
    this.district,
    this.startedAt,
    this.completedAt,
  });

  final String title;
  final ProjectStatus status;
  final String city;
  final DateTime createdAt;
  final String? description;
  final String? district;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

class EvidenceTask {
  const EvidenceTask({
    required this.title,
    required this.description,
    this.status,
    this.amount,
    this.startDate,
    this.finishDate,
    this.lastDecision,
  });

  final String title;
  final String description;
  final TaskStatus? status;
  final Money? amount;

  /// Riyadh calendar days.
  final DateTime? startDate;
  final DateTime? finishDate;

  /// The client's decision on the task's last update.
  final TaskUpdateDecision? lastDecision;
}

class EvidencePayment {
  const EvidencePayment({
    required this.stageNumber,
    required this.amount,
    this.status,
    this.method,
    this.paidAt,
    this.bankTransferStatus,
  });

  final int stageNumber;
  final Money amount;
  final PaymentStatus? status;

  /// `gateway`, `wallet` or `bank_transfer`.
  final String? method;
  final DateTime? paidAt;

  /// The receipt's status: `pending`, `confirmed`, `rejected` or `cancelled`.
  final String? bankTransferStatus;
}

/// One field of the on-chain record (owner, contractor, price…).
class EvidenceFieldCheck {
  const EvidenceFieldCheck({
    required this.field,
    required this.matches,
    this.database,
    this.chain,
  });

  /// The chain's field name, e.g. `ownerEmail`, `agreedPrice`.
  final String field;
  final String? database;
  final String? chain;
  final bool matches;
}

/// One milestone (task) of the on-chain record.
class EvidenceMilestoneCheck {
  const EvidenceMilestoneCheck({
    required this.index,
    required this.matches,
    this.description,
    this.status,
  });

  final int index;

  /// From the chain, or from the database when the chain lacks it.
  final String? description;
  final String? status;
  final bool matches;
}

/// One paid payment of the on-chain record.
class EvidencePaymentCheck {
  const EvidencePaymentCheck({
    required this.id,
    required this.matches,
    required this.isOnChain,
    required this.isInDatabase,
    this.amount,
    this.date,
  });

  final String id;
  final Money? amount;

  /// The payment's day, as written on the chain.
  final String? date;
  final bool matches;
  final bool isOnChain;
  final bool isInDatabase;
}
