import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_raw_data_model.dart';

void main() {
  test('fromJson maps raw aggregated dashboard data correctly', () {
    final json = {
      'profile': {
        'company_name': 'مؤسسة البناء المتين',
        'verification_status': 'verified',
      },
      'payments': [
        {
          'amount': 12500.0,
          'status': 'paid',
          'paid_at': '2026-10-15T10:00:00.000Z',
        },
      ],
      'opportunities_count': 5,
      'projects': [
        {
          'id': 'proj-1',
          'title': 'ترميم فيلا سكنية',
          'owner_name': 'أحمد العتيبي',
          'status': 'in_progress',
          'created_at': '2026-10-10T12:00:00.000Z',
        },
      ],
      'tasks': [
        {'id': 'task-1', 'project_id': 'proj-1', 'status': 'approved'},
      ],
      'offers': [
        {
          'id': 'offer-1',
          'project_id': 'proj-1',
          'project_title': 'ترميم فيلا سكنية',
          'amount': 3200.0,
          'status': 'pending',
          'created_at': '2026-10-12T09:30:00.000Z',
        },
      ],
    };

    final model = ContractorDashboardRawDataModel.fromJson(json);

    expect(model.profile.companyName, 'مؤسسة البناء المتين');
    expect(model.profile.verificationStatus, VerificationStatus.verified);
    expect(model.payments.length, 1);
    expect(model.payments.first.amount.halalas, 1250000);
    expect(model.payments.first.status, PaymentStatus.paid);
    expect(model.opportunitiesCount, 5);
    expect(model.projects.length, 1);
    expect(model.projects.first.title, 'ترميم فيلا سكنية');
    expect(model.projects.first.ownerName, 'أحمد العتيبي');
    expect(model.projects.first.status, ProjectStatus.inProgress);
    expect(model.tasks.length, 1);
    expect(model.tasks.first.status, TaskStatus.approved);
    expect(model.offers.length, 1);
    expect(model.offers.first.status, OfferStatus.pending);
  });
}
