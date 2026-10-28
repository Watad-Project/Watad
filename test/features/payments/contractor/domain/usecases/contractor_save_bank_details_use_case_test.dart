import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_check.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_request.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_save_bank_details_use_case.dart';

import '../../../../../helpers/fake_contractor_payments_repository.dart';

void main() {
  const typed = ContractorBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );
  const before = ContractorBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'البنك الأهلي السعودي',
    iban: 'SA0380000000608010167519',
  );
  const valid = ContractorBankDetailsCheck(details: typed);

  Failure failureOf(Result<ContractorBankDetails> result) =>
      (result as Failed<ContractorBankDetails>).failure;

  test('adds the details when nothing is saved yet', () async {
    final repository = FakeContractorPaymentsRepository();

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid),
    );

    expect(repository.added, [same(typed)]);
    expect(repository.updated, isEmpty);
    expect((result as Success<ContractorBankDetails>).data, same(typed));
  });

  test('changes them when they exist', () async {
    final repository = FakeContractorPaymentsRepository()..saved = before;

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid, saved: before),
    );

    expect(repository.updated, [same(typed)]);
    expect(repository.added, isEmpty);
    expect((result as Success<ContractorBankDetails>).data, same(typed));
  });

  test('returns what the server stored, read back after the write', () async {
    // Not what was sent, so the test sees where the answer comes from.
    const stored = ContractorBankDetails(
      beneficiaryName: 'مؤسسة البناء المتين للمقاولات',
      bankName: 'مصرف الراجحي',
      iban: 'SA0380000000608010167519',
    );
    final repository = FakeContractorPaymentsRepository()
      ..readResult = const Success(stored);

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid),
    );

    expect((result as Success<ContractorBankDetails>).data, same(stored));
  });

  test('refuses a form with a problem, and writes nothing', () async {
    final repository = FakeContractorPaymentsRepository();

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(
        check: ContractorBankDetailsCheck(
          details: typed,
          ibanError: 'validation.iban_checksum',
        ),
      ),
    );

    final failure = failureOf(result);
    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'validation.iban_checksum');
    expect(repository.added, isEmpty);
    expect(repository.updated, isEmpty);
  });

  test('passes on a refused write: details added meanwhile (23505)', () async {
    final repository = FakeContractorPaymentsRepository()
      ..addResult = const Failed(ConflictFailure());

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid),
    );

    expect(failureOf(result), isA<ConflictFailure>());
  });

  test('passes on a refused write: a suspended contractor (42501)', () async {
    final repository = FakeContractorPaymentsRepository()
      ..saved = before
      ..updateResult = const Failed(PermissionFailure());

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid, saved: before),
    );

    expect(failureOf(result), isA<PermissionFailure>());
  });

  test('written, but not there to read back: NotFoundFailure', () async {
    final repository = FakeContractorPaymentsRepository()
      ..readResult = const Success(null);

    final result = await ContractorSaveBankDetailsUseCase(repository)(
      const ContractorBankDetailsRequest(check: valid),
    );

    expect(failureOf(result), isA<NotFoundFailure>());
  });
}
