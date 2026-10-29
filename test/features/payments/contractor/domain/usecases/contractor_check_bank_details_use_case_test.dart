import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_check.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_draft.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_check_bank_details_use_case.dart';

void main() {
  const useCase = ContractorCheckBankDetailsUseCase();
  const validIban = 'SA0380000000608010167519';

  Future<ContractorBankDetailsCheck> check({
    String beneficiaryName = 'مؤسسة البناء المتين',
    String bankName = 'مصرف الراجحي',
    String iban = validIban,
  }) async {
    final result = await useCase(
      ContractorBankDetailsDraft(
        beneficiaryName: beneficiaryName,
        bankName: bankName,
        iban: iban,
      ),
    );
    return (result as Success<ContractorBankDetailsCheck>).data;
  }

  group('the IBAN', () {
    test('a valid one passes as it is', () async {
      final result = await check();

      expect(result.isValid, isTrue);
      expect(result.firstError, isNull);
      expect(result.details.iban, validIban);
    });

    test('takes spaces, dashes and lower case, like the database', () async {
      for (final typed in [
        'SA03 8000 0000 6080 1016 7519',
        'sa03-8000-0000-6080-1016-7519',
        '  Sa0380000000608010167519 ',
        'SA03\t8000 0000\n6080 1016 7519',
      ]) {
        final result = await check(iban: typed);

        expect(result.details.iban, validIban, reason: typed);
        expect(result.ibanError, isNull, reason: typed);
      }
    });

    test('reads Arabic-Indic and Persian digits as 0-9', () async {
      for (final typed in [
        'SA٠٣ ٨٠٠٠ ٠٠٠٠ ٦٠٨٠ ١٠١٦ ٧٥١٩',
        'SA۰۳۸۰۰۰۰۰۰۰۶۰۸۰۱۰۱۶۷۵۱۹',
        'sa٠٣-۸۰۰۰-0000 6080 1016 7519',
      ]) {
        final result = await check(iban: typed);

        expect(result.details.iban, validIban, reason: typed);
        expect(result.ibanError, isNull, reason: typed);
      }
    });

    test('is required', () async {
      for (final typed in ['', '   ', ' - - ']) {
        final result = await check(iban: typed);

        expect(result.ibanError, 'validation.iban_required', reason: typed);
      }
    });

    test('is SA and 22 more characters: no shorter, no longer', () async {
      for (final typed in [
        'SA038000000060801016751',
        'SA03800000006080101675190',
        'SA03',
        'GB0380000000608010167519',
        '0380000000608010167519SA',
        'SAXX80000000608010167519',
        'SA0380000000608010167519.',
        'SA03800000006080101675+9',
      ]) {
        final result = await check(iban: typed);

        expect(result.ibanError, 'validation.iban_invalid', reason: typed);
        expect(result.isValid, isFalse, reason: typed);
      }
    });

    test('needs check digits that add up', () async {
      final result = await check(iban: 'SA0480000000608010167519');

      expect(result.ibanError, 'validation.iban_checksum');
      expect(result.isValid, isFalse);
    });

    test('catches a typo in the account number too', () async {
      final result = await check(iban: 'SA0380000000608010167591');

      expect(result.ibanError, 'validation.iban_checksum');
    });
  });

  group('the names', () {
    test('are trimmed', () async {
      final result = await check(
        beneficiaryName: '  مؤسسة البناء المتين ',
        bankName: ' مصرف الراجحي  ',
      );

      expect(result.details.beneficiaryName, 'مؤسسة البناء المتين');
      expect(result.details.bankName, 'مصرف الراجحي');
      expect(result.isValid, isTrue);
    });

    test('the beneficiary has 2 to 150 characters', () async {
      for (final name in ['أب', 'أ' * 150, ' ${'أ' * 150} ']) {
        final result = await check(beneficiaryName: name);

        expect(result.beneficiaryNameError, isNull, reason: name);
      }
      for (final name in ['', '   ', 'أ', ' أ ', 'أ' * 151]) {
        final result = await check(beneficiaryName: name);

        expect(
          result.beneficiaryNameError,
          'validation.beneficiary_name_invalid',
          reason: name,
        );
      }
    });

    test('the bank has 2 to 100 characters', () async {
      for (final name in ['بن', 'ب' * 100]) {
        final result = await check(bankName: name);

        expect(result.bankNameError, isNull, reason: name);
      }
      for (final name in ['', 'ب', 'ب' * 101]) {
        final result = await check(bankName: name);

        expect(
          result.bankNameError,
          'validation.bank_name_invalid',
          reason: name,
        );
      }
    });

    test('count characters like Postgres, not UTF-16 units', () async {
      // Each of these is one character, but two UTF-16 units.
      expect((await check(beneficiaryName: '😀' * 150)).isValid, isTrue);
      expect(
        (await check(beneficiaryName: '😀' * 151)).beneficiaryNameError,
        'validation.beneficiary_name_invalid',
      );
    });
  });

  test('the first problem follows the order of the form', () async {
    final result = await check(
      beneficiaryName: 'أ',
      bankName: 'ب',
      iban: 'SA04',
    );

    expect(result.firstError, 'validation.beneficiary_name_invalid');
    expect(result.bankNameError, 'validation.bank_name_invalid');
    expect(result.ibanError, 'validation.iban_invalid');
  });
}
