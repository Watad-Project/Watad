import 'package:watad/core/utils/money.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_details.dart';

/// A deed under review: the project it proves, its owner and the deed file.
class AdminDeedDetails extends AdminReviewDetails {
  const AdminDeedDetails({
    required super.target,
    required super.requester,
    required this.title,
    required this.deedUrl,
    required this.deedPath,
    super.requestedAt,
    this.description,
    this.budget,
    this.city,
    this.district,
    this.photoUrls = const [],
  });

  final String title;
  final String? description;
  final Money? budget;
  final String? city;
  final String? district;

  /// The site photos the client added.
  final List<String> photoUrls;

  /// A signed URL to the deed, valid for a few minutes. Never a public URL.
  final String deedUrl;

  /// The deed's path in the private `project-deeds` bucket.
  final String deedPath;

  /// Whether the deed is a PDF (the rest are images).
  bool get isDeedPdf => deedPath.toLowerCase().endsWith('.pdf');
}
