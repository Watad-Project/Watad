import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';

void main() {
  test('fromJson parses a realistic v_project_offers row', () {
    final offer = ClientProjectOfferModel.fromJson({
      'id': 'off-1',
      'project_id': 'proj-1',
      'amount': 45000.75,
      'status': 'pending',
      'created_at': '2026-10-15T10:00:00+00:00',
      'contractor_name': 'Watad Contracting Ltd',
      'contractor_rating': 4.8,
      'is_contractor_verified': true,
      'duration_months': 3,
      'message': 'We have extensive experience in this area.',
    });

    expect(offer.id, 'off-1');
    expect(offer.projectId, 'proj-1');
    expect(offer.amount.halalas, 4500075);
    expect(offer.status, OfferStatus.pending);
    expect(offer.createdAt.isUtc, isTrue);
    expect(offer.contractorName, 'Watad Contracting Ltd');
    expect(offer.contractorRating, 4.8);
    expect(offer.isContractorVerified, isTrue);
    expect(offer.durationMonths, 3);
    expect(offer.message, 'We have extensive experience in this area.');
  });
}
