import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/home/client/datasource/models/client_home_profile_model.dart';

void main() {
  test('fromJson maps the v_my_profile row and the phone check', () {
    final model = ClientHomeProfileModel.fromJson({
      'full_name': ' عبدالله الحربي ',
      'is_phone_verified': true,
    });

    expect(model.fullName, 'عبدالله الحربي');
    expect(model.isPhoneVerified, isTrue);
  });

  test('no name and no confirmed phone', () {
    final model = ClientHomeProfileModel.fromJson({'full_name': null});

    expect(model.fullName, isEmpty);
    expect(model.isPhoneVerified, isFalse);
  });
}
