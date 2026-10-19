import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';

/// A pending license: the business, its owner and the files it sent.
class AdminLicenseDetails extends AdminReviewDetails {
  const AdminLicenseDetails({
    required super.target,
    required super.requester,
    required this.companyName,
    required this.crNumber,
    required this.documents,
    super.requestedAt,
    this.specializedField,
    this.city,
  });

  final String companyName;

  /// The commercial registration number, 10 digits.
  final String crNumber;
  final String? specializedField;

  /// Where the business works.
  final String? city;

  /// The files, oldest first.
  final List<AdminReviewDocument> documents;

  @override
  bool get hasFiles => documents.any((document) => document.url != null);
}
