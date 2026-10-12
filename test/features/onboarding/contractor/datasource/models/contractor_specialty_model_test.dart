import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/onboarding/contractor/datasource/models/contractor_specialty_model.dart';

void main() {
  group('ContractorSpecialtyModel', () {
    test('fromJson parses realistic row from businesses table', () {
      final json = {
        'company_name': 'شركة البناء المتقدم',
        'cr_number': '1010123456',
        'specialized_field': 'مقاولات عامة',
      };

      final model = ContractorSpecialtyModel.fromJson(json);

      expect(model.specializedField, 'مقاولات عامة');
    });

    test('toJson serializes specialized_field column', () {
      const model = ContractorSpecialtyModel(specializedField: 'تشطيبات');

      final json = model.toJson();

      expect(json, {'specialized_field': 'تشطيبات'});
    });
  });
}
