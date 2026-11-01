import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_draft.dart';
import 'package:watad/features/profile/shared/domain/usecases/check_profile_form_use_case.dart';

void main() {
  Future<ProfileFormCheck> check(ProfileFormDraft draft) async =>
      switch (await const CheckProfileFormUseCase()(draft)) {
        Success(:final data) => data,
        Failed() => throw StateError('The check always succeeds'),
      };

  /// A business form with every field right, but [fullName], [companyName]
  /// or [crNumber] when given.
  ProfileFormDraft business({
    String fullName = 'خالد الحربي',
    String companyName = 'مؤسسة البناء المتين',
    String crNumber = '1010123456',
  }) => ProfileFormDraft(
    fullName: fullName,
    companyName: companyName,
    crNumber: crNumber,
  );

  group('the name: 2 to 100 characters after trimming', () {
    test('1 and 101 are refused; 2 and 100 are fine', () async {
      expect(
        (await check(ProfileFormDraft(fullName: 'س' * 1))).fullNameError,
        'profile.edit.name_invalid',
      );
      expect(
        (await check(ProfileFormDraft(fullName: 'س' * 2))).fullNameError,
        isNull,
      );
      expect(
        (await check(ProfileFormDraft(fullName: 'س' * 100))).fullNameError,
        isNull,
      );
      expect(
        (await check(ProfileFormDraft(fullName: 'س' * 101))).fullNameError,
        'profile.edit.name_invalid',
      );
    });

    test('counted in characters, not UTF-16 units', () async {
      // 100 emoji are 200 UTF-16 units, but 100 characters.
      final result = await check(ProfileFormDraft(fullName: '😀' * 100));

      expect(result.fullNameError, isNull);
    });

    test('trimmed before it is counted and saved', () async {
      final result = await check(const ProfileFormDraft(fullName: '  س  '));

      expect(result.fullName, 'س');
      expect(result.fullNameError, 'profile.edit.name_invalid');
    });
  });

  group('the company name: 2 to 150 characters after trimming', () {
    test('1 and 151 are refused; 2 and 150 are fine', () async {
      Future<String?> errorFor(int length) async =>
          (await check(business(companyName: 'م' * length))).companyNameError;

      expect(await errorFor(1), 'profile.edit.company_name_invalid');
      expect(await errorFor(2), isNull);
      expect(await errorFor(150), isNull);
      expect(await errorFor(151), 'profile.edit.company_name_invalid');
    });
  });

  group('the CR number: exactly 10 digits', () {
    test('9 and 11 digits are refused; 10 are fine', () async {
      expect(
        (await check(business(crNumber: '101012345'))).crNumberError,
        'profile.edit.cr_number_invalid',
      );
      expect(
        (await check(business(crNumber: '1010123456'))).crNumberError,
        isNull,
      );
      expect(
        (await check(business(crNumber: '10101234567'))).crNumberError,
        'profile.edit.cr_number_invalid',
      );
    });

    test('letters are refused', () async {
      final result = await check(business(crNumber: '101012345a'));

      expect(result.crNumberError, 'profile.edit.cr_number_invalid');
    });

    test('Arabic-Indic digits and spaces are cleaned', () async {
      final arabic = await check(business(crNumber: '١٠١٠١٢٣٤٥٦'));
      final spaced = await check(business(crNumber: ' 1010 123 456 '));

      expect(arabic.crNumber, '1010123456');
      expect(arabic.crNumberError, isNull);
      expect(spaced.crNumber, '1010123456');
      expect(spaced.isValid, isTrue);
    });
  });

  test("a client's form has no business fields to check", () async {
    final result = await check(
      const ProfileFormDraft(fullName: 'سارة العتيبي'),
    );

    expect(result.companyName, isNull);
    expect(result.crNumber, isNull);
    expect(result.isValid, isTrue);
  });

  test('the first problem is the first field that has one', () async {
    final result = await check(business(fullName: 'س', crNumber: '123'));

    expect(result.firstError, 'profile.edit.name_invalid');
    expect(result.isValid, isFalse);
  });
}
