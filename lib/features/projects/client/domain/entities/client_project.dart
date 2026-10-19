import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

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
  final DateTime createdAt;
}
