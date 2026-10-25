import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/payments/client/datasource/remote/client_payments_remote_data_source.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_task.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';

class ClientPaymentsRepositoryImpl implements ClientPaymentsRepository {
  const ClientPaymentsRepositoryImpl(this._remote);

  final ClientPaymentsRemoteDataSource _remote;

  @override
  Future<Result<List<ClientPaymentTask>>> getTasks(String projectId) =>
      guardSupabaseCall(() => _remote.getTasks(projectId));
}
