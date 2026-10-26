import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';

abstract interface class ClientPaymentsRepository {
  /// The tasks of one of the client's projects with their payment stages,
  /// by start date (tasks without one last), then by when they were added.
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId);

  /// The same, for the tasks with [taskIds] only.
  Future<Result<List<ClientPaymentTask>>> getTasksByIds(
    String projectId,
    List<String> taskIds,
  );

  /// Where the contractor of one of the client's projects is paid by bank
  /// transfer; null until they add their bank details.
  Future<Result<ClientBankDetails?>> getBankDetails(String projectId);

  /// Sends [receipt] for one payment stage: uploads it, then submits it as
  /// a bank transfer, which the contractor confirms.
  Future<Result<void>> submitBankTransfer(
    String paymentId,
    ClientReceipt receipt,
  );
}
