import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';

/// A project the client posted: a `v_my_projects` row with
/// `my_role = 'owner'`.
class ClientProject {
  const ClientProject({
    required this.id,
    required this.title,
    required this.status,
    required this.city,
    required this.pendingOfferCount,
    required this.createdAt,
    this.district,
    this.budget,
    this.deedStatus = ClientDeedVerificationStatus.none,
    this.deedRejectionReason,
    this.photoUrl,
    this.contractorName,
    this.takerId,
    this.agreedAmount,
    this.taskCount = 0,
    this.approvedTaskCount = 0,
  });

  final String id;
  final String title;
  final ProjectStatus status;
  final String city;
  final String? district;

  /// The budget the client declared, if any.
  final Money? budget;

  /// Offers still waiting for the client's answer.
  final int pendingOfferCount;

  /// The ownership deed's review: a project with a deed under review stays
  /// a draft, hidden from contractors, until an admin verifies it.
  final ClientDeedVerificationStatus deedStatus;

  /// Why the admin rejected the deed; the client uploads a new one.
  final String? deedRejectionReason;
  final DateTime createdAt;

  /// The first photo the client uploaded with the project, if any.
  final String? photoUrl;

  /// The business working on it, once an offer was accepted.
  final String? contractorName;

  /// The contractor's user id, once an offer is accepted: who «مراسلة»
  /// opens a chat with.
  final String? takerId;

  /// The accepted offer's amount.
  final Money? agreedAmount;

  /// The project's tasks, without the rejected ones, and how many of them
  /// the client approved.
  final int taskCount;
  final int approvedTaskCount;

  /// From 0 to 1: the approved share of the tasks. Null without tasks: the
  /// work is still being planned.
  double? get progress =>
      taskCount == 0 ? null : (approvedTaskCount / taskCount).clamp(0.0, 1.0);
}
