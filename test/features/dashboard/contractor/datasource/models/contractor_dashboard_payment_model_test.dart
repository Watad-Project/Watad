import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_payment_model.dart';

void main() {
  test('fromJson maps v_project_payments row correctly', () {
    final json = {
      'amount': 1500.50,
      'status': 'paid',
      'paid_at': '2026-10-15T14:30:00.000Z',
      'my_role': 'payee',
    };

    final model = ContractorDashboardPaymentModel.fromJson(json);

    expect(model.amount.halalas, 150050);
    expect(model.status, PaymentStatus.paid);
    expect(model.paidAt, DateTime.parse('2026-10-15T14:30:00.000Z'));
  });

  test('fromJson handles null paid_at and defaults', () {
    final json = {'amount': 200.0, 'status': 'processing', 'paid_at': null};

    final model = ContractorDashboardPaymentModel.fromJson(json);

    expect(model.amount.halalas, 20000);
    expect(model.status, PaymentStatus.processing);
    expect(model.paidAt, isNull);
  });
}
