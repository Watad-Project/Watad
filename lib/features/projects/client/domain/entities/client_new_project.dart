import 'package:watad/core/utils/money.dart';

/// What the client fills in to create a project: only the `projects`
/// INSERT columns of ARCHITECTURE.md §3a.
class ClientNewProject {
  const ClientNewProject({
    required this.title,
    required this.city,
    this.description,
    this.district,
    this.budget,
    this.addressId,
    this.publish = false,
  });

  final String title;
  final String city;
  final String? description;
  final String? district;
  final Money? budget;
  final String? addressId;

  /// true: the project starts as `open`; false: as `draft`.
  final bool publish;
}
