import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/kyc/shared/datasource/models/kyc_document_model.dart';

void main() {
  test('fromJson maps a realistic Supabase row to KycDocumentModel', () {
    final row = {
      'id': 'doc-123',
      'document_type': 'commercial_registration',
      'verification_status': 'verified',
      'rejection_reason': null,
      'specialized_field': 'general_contracting',
    };

    final model = KycDocumentModel.fromJson(row);

    expect(model.id, 'doc-123');
    expect(model.documentType, BusinessDocumentType.commercialRegistration);
    expect(model.status, VerificationStatus.verified);
    expect(model.rejectionReason, isNull);
    expect(model.specializedField, 'general_contracting');
  });

  test('fromJson handles rejected status and rejection reason', () {
    final row = {
      'id': 'doc-456',
      'document_type': 'vat_certificate',
      'verification_status': 'rejected',
      'rejection_reason': 'Document is blurry',
      'specialized_field': null,
    };

    final model = KycDocumentModel.fromJson(row);

    expect(model.id, 'doc-456');
    expect(model.documentType, BusinessDocumentType.vatCertificate);
    expect(model.status, VerificationStatus.rejected);
    expect(model.rejectionReason, 'Document is blurry');
  });

  test('fromJson defaults to unverified for unknown status or missing row', () {
    final row = {'id': 'doc-789', 'verification_status': 'unknown_status'};

    final model = KycDocumentModel.fromJson(row);

    expect(model.status, VerificationStatus.unverified);
  });
}
