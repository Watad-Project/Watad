import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';

/// Checks the receipt the client picked, before it's attached (GRA-52):
/// the `bank-transfer-receipts` bucket takes PDF, JPEG and PNG files up to
/// 10 MB, so anything else is refused with why.
class ClientCheckReceiptUseCase
    implements UseCase<ClientReceipt, ClientReceipt> {
  const ClientCheckReceiptUseCase();

  @override
  Future<Result<ClientReceipt>> call(ClientReceipt params) async =>
      switch (params.problem) {
        final problem? => Failed(ValidationFailure(problem.messageKey)),
        null => Success(params),
      };
}
