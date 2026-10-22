import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';

void main() {
  test('fromJson maps a v_project_offers row', () {
    final model = ClientProjectOfferModel.fromJson({
      'id': 'o-1',
      'project_id': 'p-1',
      'amount': 465000,
      'status': 'pending',
      'message': ' يشمل التشطيب الخارجي ',
      'created_at': '2026-10-18T09:00:00+00:00',
      'provider_company_name': 'مؤسسة البناء المتين',
      'provider_is_verified': true,
      'provider_rating_avg': 4.8,
      'provider_rating_count': 12,
    });

    expect(model.id, 'o-1');
    expect(model.projectId, 'p-1');
    expect(model.amount, const Money.halalas(46500000));
    expect(model.status, OfferStatus.pending);
    expect(model.message, 'يشمل التشطيب الخارجي');
    expect(model.providerName, 'مؤسسة البناء المتين');
    expect(model.isProviderVerified, isTrue);
    expect(model.providerRatingAvg, 4.8);
    expect(model.providerRatingCount, 12);
  });

  test('an offer without a note from a contractor with no ratings', () {
    final model = ClientProjectOfferModel.fromJson({
      'id': 'o-2',
      'project_id': 'p-1',
      'amount': 510000,
      'status': 'rejected',
      'message': '  ',
      'created_at': '2026-10-18T09:00:00+00:00',
      'provider_company_name': 'مؤسسة الأساس الحديث',
      'provider_is_verified': false,
      'provider_rating_avg': null,
      'provider_rating_count': 0,
    });

    expect(model.message, isNull);
    expect(model.providerRatingAvg, isNull);
    expect(model.isProviderVerified, isFalse);
  });
}
