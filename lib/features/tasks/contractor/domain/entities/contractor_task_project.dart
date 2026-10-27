import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// A contract project as seen on the contractor's project schedule screen
/// (GRA-37), backed by `v_my_projects` (`my_role = 'taker'`).
class ContractorTaskProject {
  const ContractorTaskProject({
    required this.id,
    required this.title,
    required this.status,
    required this.ownerName,
    required this.totalPaid,
    required this.totalScheduled,
    required this.createdAt,
    this.city,
    this.district,
    this.agreedAmount,
    this.budget,
    this.photoUrl,
    this.completedAt,
  });

  final String id;
  final String title;
  final ProjectStatus status;
  final String ownerName;
  final String? city;
  final String? district;
  final Money? agreedAmount;
  final Money? budget;
  final Money totalPaid;
  final Money totalScheduled;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// The contract's agreed amount, falling back to the project's budget.
  Money? get contractAmount => agreedAmount ?? budget;

  /// Only `in_progress` contracts can add or update tasks; `completed`
  /// contracts are read-only.
  bool get isInProgress => status == ProjectStatus.inProgress;

  /// «فيلا سكنية — حي الياسمين» when [district] is present and not already
  /// part of [title].
  String get displayTitle {
    final trimmedDistrict = district?.trim();
    if (trimmedDistrict == null ||
        trimmedDistrict.isEmpty ||
        title.contains(trimmedDistrict)) {
      return title;
    }
    return '$title — $trimmedDistrict';
  }
}
