import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/payments/contractor/datasource/models/contractor_bank_details_model.dart';

void main() {
  test('fromJson maps a v_contractor_bank_details row', () {
    final details = ContractorBankDetailsModel.fromJson(const {
      'beneficiary_name': 'مؤسسة البناء المتين',
      'bank_name': 'مصرف الراجحي',
      'iban': 'SA0380000000608010167519',
    });

    expect(details.beneficiaryName, 'مؤسسة البناء المتين');
    expect(details.bankName, 'مصرف الراجحي');
    expect(details.iban, 'SA0380000000608010167519');
  });
}
