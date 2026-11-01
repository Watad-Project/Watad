import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_format.dart';

void main() {
  test('a Saudi mobile number is grouped to read it out', () {
    expect(ProfileFormat.phone('+966512345678'), '+966 51 234 5678');
  });

  test('anything else is shown as it is', () {
    expect(ProfileFormat.phone('0512345678'), '0512345678');
    expect(ProfileFormat.phone('+96651234567'), '+96651234567');
  });
}
