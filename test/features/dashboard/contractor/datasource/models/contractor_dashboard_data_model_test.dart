import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_data_model.dart';

void main() {
  test('fromJson maps full dashboard aggregate correctly', () {
    final json = {
      'profile': {
        'company_name': 'مؤسسة البناء المتين',
        'verification_status': 'verified',
      },
      'earnings': {'this_month_earnings': 15000.0, 'pending_transfers': 5000.0},
      'opportunities_count': 6,
      'active_projects': [
        {
          'id': 'p-1',
          'title': 'مشروع بناء',
          'client_name': 'عميل تجريبي',
          'status': 'in_progress',
          'approved_tasks_count': 2,
          'total_tasks_count': 4,
          'created_at': '2026-10-10T10:00:00.000Z',
          'budget': 20000.0,
          'city': 'المدينة',
        },
      ],
      'my_offers': [
        {
          'id': 'o-1',
          'project_id': 'p-1',
          'project_title': 'مشروع بناء',
          'amount': 3200.0,
          'status': 'pending',
          'created_at': '2026-10-11T10:00:00.000Z',
        },
      ],
    };

    final model = ContractorDashboardDataModel.fromJson(json);

    expect(model.profile.companyName, 'مؤسسة البناء المتين');
    expect(model.profile.verificationStatus, VerificationStatus.verified);
    expect(model.earnings.thisMonthEarnings.halalas, 1500000);
    expect(model.earnings.pendingTransfers.halalas, 500000);
    expect(model.opportunitiesCount, 6);
    expect(model.activeProjects.length, 1);
    expect(model.activeProjects.first.title, 'مشروع بناء');
    expect(model.activeProjects.first.status, ProjectStatus.inProgress);
    expect(model.myOffers.length, 1);
    expect(model.myOffers.first.status, OfferStatus.pending);
  });
}
