import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/datasource/models/kyc_document_model.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';

void main() {
  test('fromJson maps a realistic Supabase row to KycDocumentModel', () {
    final row = {
      'id': 'doc-123',
      'document_type': 'license',
      'status': 'verified',
      'rejection_reason': null,
      'specialized_field': 'general_contracting',
    };

    final model = KycDocumentModel.fromJson(row);

    expect(model.id, 'doc-123');
    expect(model.documentType, KycDocumentType.license);
    expect(model.status, VerificationStatus.verified);
    expect(model.rejectionReason, isNull);
    expect(model.specializedField, 'general_contracting');
  });

  test('fromJson handles rejected deed and fallback statuses', () {
    final row = {
      'id': 'doc-456',
      'document_type': 'deed',
      'status': 'rejected',
      'rejection_reason': 'Document is blurry',
      'specialized_field': null,
    };

    final model = KycDocumentModel.fromJson(row);

    expect(model.id, 'doc-456');
    expect(model.documentType, KycDocumentType.deed);
    expect(model.status, VerificationStatus.rejected);
    expect(model.rejectionReason, 'Document is blurry');
  });

  test('fromJson defaults to pending for unknown status', () {
    final row = {
      'id': 'doc-789',
      'document_type': 'license',
      'status': 'unknown_status',
    };

    final model = KycDocumentModel.fromJson(row);

    expect(model.status, VerificationStatus.pending);
  });
}
