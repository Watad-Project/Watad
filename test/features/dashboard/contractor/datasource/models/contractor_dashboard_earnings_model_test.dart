import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/dashboard/contractor/datasource/models/contractor_dashboard_earnings_model.dart';

void main() {
  test('fromJson maps earnings summary correctly', () {
    final json = {
      'this_month_earnings': 12500.50,
      'pending_transfers': 3200.00,
    };

    final model = ContractorDashboardEarningsModel.fromJson(json);

    expect(model.thisMonthEarnings.halalas, 1250050);
    expect(model.pendingTransfers.halalas, 320000);
  });

  test('fromJson defaults to zero when numbers are missing', () {
    final model = ContractorDashboardEarningsModel.fromJson({});

    expect(model.thisMonthEarnings.halalas, 0);
    expect(model.pendingTransfers.halalas, 0);
  });
}
