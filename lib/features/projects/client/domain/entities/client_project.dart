import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// A project the signed-in user owns: a `v_my_projects` row with
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
  final int pendingOfferCount;
  final DateTime createdAt;
  final String? district;
  final Money? budget;
}
