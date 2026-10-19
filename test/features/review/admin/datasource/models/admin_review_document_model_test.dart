import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/features/review/admin/datasource/models/admin_review_document_model.dart';

void main() {
  test('fromJson maps a v_business_documents row and its signed URL', () {
    final row = {
      'id': 'doc-1',
      'document_type': 'commercial_registration',
      'storage_path': 'b-1/commercial_registration/license.PDF',
      'created_at': '2026-10-18T09:31:12.345+00:00',
      'url': 'https://example.supabase.co/storage/v1/object/sign/x?token=t',
    };

    final model = AdminReviewDocumentModel.fromJson(row);

    expect(model.id, 'doc-1');
    expect(model.documentType, BusinessDocumentType.commercialRegistration);
    expect(model.storagePath, 'b-1/commercial_registration/license.PDF');
    expect(model.createdAt, DateTime.utc(2026, 10, 18, 9, 31, 12, 345));
    expect(model.url, startsWith('https://'));
    expect(model.isPdf, isTrue);
  });

  test('an image is not a PDF', () {
    final model = AdminReviewDocumentModel.fromJson({
      'id': 'doc-2',
      'document_type': 'national_address',
      'storage_path': 'b-1/national_address/photo.jpg',
      'created_at': '2026-10-18T09:31:12+00:00',
      'url': 'https://example.supabase.co/x',
    });

    expect(model.documentType, BusinessDocumentType.nationalAddress);
    expect(model.isPdf, isFalse);
  });
}
