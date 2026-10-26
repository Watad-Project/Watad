import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/payments/client/datasource/remote/client_payments_remote_data_source.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

class ClientPaymentsRepositoryImpl implements ClientPaymentsRepository {
  const ClientPaymentsRepositoryImpl(this._remote);

  final ClientPaymentsRemoteDataSource _remote;

  @override
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId) =>
      guardSupabaseCall(() => _remote.getTasks(projectId));

  @override
  Future<Result<List<ClientPaymentTask>>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  ) => guardSupabaseCall(() => _remote.getTasksByIds(projectId, taskIds));

  @override
  Future<Result<ClientBankDetails?>> getBankDetails(String projectId) =>
      guardSupabaseCall(() => _remote.getBankDetails(projectId));

  @override
  Future<Result<void>> submitBankTransfer(
    String paymentId,
    ClientReceipt receipt,
  ) => guardSupabaseCall(() => _remote.submitBankTransfer(paymentId, receipt));
}
