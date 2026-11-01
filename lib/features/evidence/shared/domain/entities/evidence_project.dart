import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/utils/money.dart';

/// One of my contracted projects, to export: a `v_my_projects` row with an
/// accepted offer, in progress or completed.
class EvidenceProject {
  const EvidenceProject({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.otherParty,
    this.agreedAmount,
  });

  final String id;
  final String title;
  final ProjectStatus status;
  final DateTime createdAt;

  /// The contractor's company when I'm the client, the client's name when
  /// I'm the contractor.
  final String? otherParty;
  final Money? agreedAmount;
}
