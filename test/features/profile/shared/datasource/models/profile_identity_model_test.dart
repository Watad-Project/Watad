import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_identity_model.dart';

void main() {
  test('fromJson maps a v_my_identity row', () {
    final identity = ProfileIdentityModel.fromJson(const {
      'national_id': '1012345678',
      'phone': '+966512345678',
    });

    expect(identity.nationalId, '1012345678');
    expect(identity.phone, '+966512345678');
  });
}
