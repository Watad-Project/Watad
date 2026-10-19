import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_offer_model.dart';

void main() {
  test('fromJson maps v_project_offers row correctly', () {
    final json = {
      'id': 'offer-1',
      'project_id': 'proj-1',
      'project_title': 'أعمال كهرباء وسباكة',
      'amount': 3200.0,
      'status': 'pending',
      'created_at': '2026-10-12T09:30:00.000Z',
    };

    final model = ContractorDashboardOfferModel.fromJson(json);

    expect(model.id, 'offer-1');
    expect(model.projectId, 'proj-1');
    expect(model.projectTitle, 'أعمال كهرباء وسباكة');
    expect(model.amount.halalas, 320000);
    expect(model.status, OfferStatus.pending);
  });

  test('fromJson handles null or missing fields gracefully', () {
    final model = ContractorDashboardOfferModel.fromJson({});

    expect(model.id, isEmpty);
    expect(model.projectId, isEmpty);
    expect(model.projectTitle, isEmpty);
    expect(model.amount.halalas, 0);
    expect(model.status, OfferStatus.pending);
  });
}
