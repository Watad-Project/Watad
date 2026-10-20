import 'package:watad/core/enums/business_document_type.dart';

/// One file a business uploaded for review, with a short-lived link to open
/// it from the private `business-documents` bucket.
class AdminReviewDocument {
  const AdminReviewDocument({
    required this.id,
    required this.documentType,
    required this.storagePath,
    required this.createdAt,
    this.url,
  });

  final String id;
  final BusinessDocumentType documentType;
  final String storagePath;
  final DateTime createdAt;

  /// A signed URL, valid for a few minutes. Never a public URL. Null when
  /// the file isn't in storage (it was never uploaded, or was removed).
  final String? url;

  /// Whether the file is a PDF (the rest are images).
  bool get isPdf => storagePath.toLowerCase().endsWith('.pdf');
}
