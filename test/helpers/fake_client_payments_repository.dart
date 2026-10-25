import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/client_payments_injection.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

/// A hand-written [ClientPaymentsRepository]: it answers with the results
/// you set (APP_ARCHITECTURE.md §16).
class FakeClientPaymentsRepository implements ClientPaymentsRepository {
  Result<List<ClientPaymentTask>> tasksResult = const Success([]);

  @override
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId) async =>
      tasksResult;
}

/// For tests that open the payments routes: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeClientPayments([FakeClientPaymentsRepository? repository]) {
  registerClientPaymentsDependencies(getIt);
  getIt
    ..unregister<ClientPaymentsRepository>()
    ..registerSingleton<ClientPaymentsRepository>(
      repository ?? FakeClientPaymentsRepository(),
    );
}
