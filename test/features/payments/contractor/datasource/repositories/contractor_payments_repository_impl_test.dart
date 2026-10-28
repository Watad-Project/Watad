import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/datasource/models/contractor_bank_details_model.dart';
import 'package:watad/features/payments/contractor/datasource/remote/contractor_payments_remote_data_source.dart';
import 'package:watad/features/payments/contractor/datasource/repositories/contractor_payments_repository_impl.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';

class _FakeContractorPaymentsRemoteDataSource
    implements ContractorPaymentsRemoteDataSource {
  Object? error;
  ContractorBankDetailsModel? row;

  /// The writes, as `insert <iban>` or `update <iban>`, in order.
  final List<String> writes = [];

  @override
  Future<ContractorBankDetailsModel?> getMyBankDetails() async {
    final err = error;
    if (err != null) throw err;
    return row;
  }

  @override
  Future<void> addBankDetails(ContractorBankDetails details) async {
    final err = error;
    if (err != null) throw err;
    writes.add('insert ${details.iban}');
  }

  @override
  Future<void> updateBankDetails(ContractorBankDetails details) async {
    final err = error;
    if (err != null) throw err;
    writes.add('update ${details.iban}');
  }
}

void main() {
  const details = ContractorBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );

  Failure failureOf(Result<void> result) => (result as Failed<void>).failure;

  test('getMyBankDetails is null before the contractor adds them', () async {
    final result = await ContractorPaymentsRepositoryImpl(
      _FakeContractorPaymentsRemoteDataSource(),
    ).getMyBankDetails();

    expect((result as Success<ContractorBankDetails?>).data, isNull);
  });

  test('getMyBankDetails returns the saved row', () async {
    final remote = _FakeContractorPaymentsRemoteDataSource()
      ..row = ContractorBankDetailsModel.fromJson(const {
        'beneficiary_name': 'مؤسسة البناء المتين',
        'bank_name': 'مصرف الراجحي',
        'iban': 'SA0380000000608010167519',
      });

    final result = await ContractorPaymentsRepositoryImpl(remote)
        .getMyBankDetails();

    expect(
      (result as Success<ContractorBankDetails?>).data?.bankName,
      'مصرف الراجحي',
    );
  });

  test('addBankDetails inserts, updateBankDetails updates', () async {
    final remote = _FakeContractorPaymentsRemoteDataSource();
    final repository = ContractorPaymentsRepositoryImpl(remote);

    expect(await repository.addBankDetails(details), isA<Success<void>>());
    expect(await repository.updateBankDetails(details), isA<Success<void>>());
    expect(remote.writes, [
      'insert SA0380000000608010167519',
      'update SA0380000000608010167519',
    ]);
  });

  test('a second insert (23505) is a ConflictFailure', () async {
    final remote = _FakeContractorPaymentsRemoteDataSource()
      ..error = const PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

    final result = await ContractorPaymentsRepositoryImpl(remote)
        .addBankDetails(details);

    expect(failureOf(result), isA<ConflictFailure>());
  });

  test('a suspended contractor (42501) gets a PermissionFailure', () async {
    final remote = _FakeContractorPaymentsRemoteDataSource()
      ..error = const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );

    final result = await ContractorPaymentsRepositoryImpl(remote)
        .updateBankDetails(details);

    expect(failureOf(result), isA<PermissionFailure>());
  });

  test('a value the database refuses (22023) is validation.invalid', () async {
    final remote = _FakeContractorPaymentsRemoteDataSource()
      ..error = const PostgrestException(
        message: 'invalid_iban',
        code: '22023',
      );

    final failure = failureOf(
      await ContractorPaymentsRepositoryImpl(remote).addBankDetails(details),
    );

    expect(failure, isA<ValidationFailure>());
    expect(failure.messageKey, 'validation.invalid');
  });
}
