import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/contractor_payments_injection.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/repositories/contractor_payments_repository.dart';

/// A hand-written [ContractorPaymentsRepository] (APP_ARCHITECTURE.md §16).
/// Like the table, it keeps one account per contractor ([saved]), and a
/// write replaces it. Set a result to make that call fail instead.
class FakeContractorPaymentsRepository implements ContractorPaymentsRepository {
  /// The contractor's `v_contractor_bank_details` row; null until added.
  ContractorBankDetails? saved;

  /// What reading answers instead of [saved], e.g. a failure.
  Result<ContractorBankDetails?>? readResult;

  /// What a write answers instead of saving, e.g. a `ConflictFailure`.
  Result<void>? addResult;
  Result<void>? updateResult;

  /// The details written, in order.
  final List<ContractorBankDetails> added = [];
  final List<ContractorBankDetails> updated = [];

  @override
  Future<Result<ContractorBankDetails?>> getMyBankDetails() async =>
      readResult ?? Success(saved);

  @override
  Future<Result<void>> addBankDetails(ContractorBankDetails details) async {
    if (addResult case final result?) return result;
    added.add(details);
    saved = details;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateBankDetails(ContractorBankDetails details) async {
    if (updateResult case final result?) return result;
    updated.add(details);
    saved = details;
    return const Success(null);
  }
}

/// For tests that open the contractor's payments routes: the real
/// registrations, with [repository] in place of Supabase. Reset getIt and
/// AppNotificationLinks after the test.
void registerFakeContractorPayments([
  FakeContractorPaymentsRepository? repository,
]) {
  registerContractorPaymentsDependencies(getIt);
  getIt
    ..unregister<ContractorPaymentsRepository>()
    ..registerSingleton<ContractorPaymentsRepository>(
      repository ?? FakeContractorPaymentsRepository(),
    );
}
