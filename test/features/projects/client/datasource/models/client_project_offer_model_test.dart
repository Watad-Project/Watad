import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';

void main() {
  test('fromJson maps a v_project_offers row', () {
    final offer = ClientProjectOfferModel.fromJson(const {
      'id': 'offer-1',
      'project_id': 'proj-1',
      'contractor_name': 'Al-Bina Contracting',
      'contractor_rating': 4.8,
      'is_contractor_verified': true,
      'amount': 465000.0,
      'duration_months': 7,
      'status': 'pending',
      'created_at': '2026-10-14T08:00:00+00:00',
      'message': 'Includes exterior finishing',
      'contractor_avatar_url': 'avatars/c1.png',
      'contractor_id': 'user-1',
    });

    expect(offer.id, 'offer-1');
    expect(offer.projectId, 'proj-1');
    expect(offer.contractorName, 'Al-Bina Contracting');
    expect(offer.contractorRating, 4.8);
    expect(offer.isContractorVerified, isTrue);
    expect(offer.amount.halalas, 46500000);
    expect(offer.durationMonths, 7);
    expect(offer.status, OfferStatus.pending);
    expect(offer.createdAt.isUtc, isTrue);
    expect(offer.message, 'Includes exterior finishing');
  });

  test('fromJson defaults null optional values safely', () {
    final offer = ClientProjectOfferModel.fromJson(const {
      'id': 'offer-2',
      'project_id': 'proj-2',
      'created_at': '2026-10-14T08:00:00+00:00',
    });

    expect(offer.contractorName, isEmpty);
    expect(offer.contractorRating, 5.0);
    expect(offer.isContractorVerified, isTrue);
    expect(offer.amount.halalas, 0);
    expect(offer.durationMonths, 1);
    expect(offer.status, OfferStatus.pending);
    expect(offer.message, isNull);
  });
}
