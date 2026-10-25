import 'package:get_it/get_it.dart';
import 'package:watad/features/payments/client/datasource/remote/client_payments_remote_data_source.dart';
import 'package:watad/features/payments/client/datasource/repositories/client_payments_repository_impl.dart';
import 'package:watad/features/payments/client/domain/repositories/client_payments_repository.dart';
import 'package:watad/features/payments/client/domain/usecases/client_calculate_payment_total_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_payment_tasks_use_case.dart';
import 'package:watad/features/payments/client/presentation/bloc/client_new_payment_bloc.dart';

/// Registers the types of lib/features/payments/client/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerClientPaymentsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ClientPaymentsRemoteDataSource>(
      () => ClientPaymentsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ClientPaymentsRepository>(
      () => ClientPaymentsRepositoryImpl(getIt()),
    )
    // Choosing the tasks to pay (GRA-50).
    ..registerLazySingleton(() => ClientGetPaymentTasksUseCase(getIt()))
    ..registerLazySingleton(() => const ClientCalculatePaymentTotalUseCase())
    ..registerFactory(() => ClientNewPaymentBloc(getIt(), getIt()));
}
