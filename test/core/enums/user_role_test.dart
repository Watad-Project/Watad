import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/user_role.dart';

void main() {
  test('round-trips every app_role value', () {
    for (final role in UserRole.values) {
      expect(UserRole.fromJson(role.toJson()), role);
    }
    expect(UserRole.admin.toJson(), 'admin');
    expect(UserRole.user.toJson(), 'user');
  });

  test('an unknown value reads as a user', () {
    expect(UserRole.fromJson('owner'), UserRole.user);
  });
}
