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
    this.photos = const [],
    this.deedFilePath,
  });

  final String title;
  final String city;
  final String? description;
  final String? district;
  final Money? budget;
  final String? addressId;

  /// true: the project starts as `open`; false: as `draft`.
  final bool publish;

  /// Local file paths of picked photos to be uploaded to Supabase Storage.
  final List<String> photos;

  /// Local file path of picked ownership deed file.
  final String? deedFilePath;
}
