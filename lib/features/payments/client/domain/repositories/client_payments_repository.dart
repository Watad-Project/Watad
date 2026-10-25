import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';

abstract interface class ClientPaymentsRepository {
  /// The tasks of one of the client's projects with their payment stages,
  /// by start date (tasks without one last), then by when they were added.
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId);
}
