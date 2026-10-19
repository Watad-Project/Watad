import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/auth/shared/datasource/models/business_sign_up_model.dart';

void main() {
  test('fromJson maps a business sign up row correctly', () {
    final model = BusinessSignUpModel.fromJson(const {
      'company_name': 'شركة البناء الحديث',
      'cr_number': '1010123456',
      'email': 'contractor@example.com',
      'phone': '+966501234567',
      'role': 'contractor',
    });

    expect(model.companyName, 'شركة البناء الحديث');
    expect(model.crNumber, '1010123456');
    expect(model.email, 'contractor@example.com');
    expect(model.phone, '+966501234567');
    expect(model.role, 'contractor');
  });

  test('fromJson defaults role to contractor if not present', () {
    final model = BusinessSignUpModel.fromJson(const {
      'company_name': 'مؤسسة الوتد',
      'cr_number': '1010987654',
      'email': 'test@watad.sa',
      'phone': '+966555555555',
    });

    expect(model.role, 'contractor');
    expect(model.specializedField, 'contractor');
  });

  test('fromJson reads specialized_field if present', () {
    final model = BusinessSignUpModel.fromJson(const {
      'company_name': 'مؤسسة الوتد',
      'cr_number': '1010987654',
      'email': 'test@watad.sa',
      'phone': '+966555555555',
      'specialized_field': 'construction',
    });

    expect(model.specializedField, 'construction');
  });
}
