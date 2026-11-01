import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_specialty.dart';

void main() {
  // GRA-16's labels in both languages, as the translation files have them.
  const labels = {
    ProfileSpecialty.generalContracting: [
      'مقاولات عامة',
      'General Contracting',
    ],
    ProfileSpecialty.finishes: ['تشطيبات', 'Finishes'],
    ProfileSpecialty.electricalPlumbing: [
      'كهرباء وسباكة',
      'Electrical & Plumbing',
    ],
    ProfileSpecialty.renovation: ['ترميم', 'Restoration'],
    ProfileSpecialty.insulation: ['عزل', 'Insulation'],
  };

  ProfileSpecialty? match(String stored) =>
      ProfileSpecialty.match(stored, (choice) => labels[choice]!);

  test('the five choices keep GRA-16 order', () {
    expect(ProfileSpecialty.values, [
      ProfileSpecialty.generalContracting,
      ProfileSpecialty.finishes,
      ProfileSpecialty.electricalPlumbing,
      ProfileSpecialty.renovation,
      ProfileSpecialty.insulation,
    ]);
  });

  test('a label saved in Arabic or in English matches its choice', () {
    expect(match('مقاولات عامة'), ProfileSpecialty.generalContracting);
    expect(match('Restoration'), ProfileSpecialty.renovation);
    expect(match(' عزل '), ProfileSpecialty.insulation);
  });

  test('the sign-up default and an empty field are no specialty', () {
    expect(ProfileSpecialty.isUnset('contractor'), isTrue);
    expect(ProfileSpecialty.isUnset('  '), isTrue);
    expect(ProfileSpecialty.isUnset('عزل'), isFalse);
    expect(match('contractor'), isNull);
    expect(match(''), isNull);
  });

  test('text that is no label matches nothing', () {
    expect(match('fdfds'), isNull);
    expect(match('مقاولات'), isNull);
  });
}
