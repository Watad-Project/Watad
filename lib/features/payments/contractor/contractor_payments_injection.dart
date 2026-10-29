import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/contractor_payments_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/payments/contractor/datasource/remote/contractor_payments_remote_data_source.dart';
import 'package:watad/features/payments/contractor/datasource/repositories/contractor_payments_repository_impl.dart';
import 'package:watad/features/payments/contractor/domain/repositories/contractor_payments_repository.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_check_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_get_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_save_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/presentation/bloc/contractor_bank_details_bloc.dart';

/// Registers the types of lib/features/payments/contractor/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerContractorPaymentsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ContractorPaymentsRemoteDataSource>(
      () => ContractorPaymentsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ContractorPaymentsRepository>(
      () => ContractorPaymentsRepositoryImpl(getIt()),
    )
    // The bank account clients transfer to (GRA-64).
    ..registerLazySingleton(() => ContractorGetBankDetailsUseCase(getIt()))
    ..registerLazySingleton(() => const ContractorCheckBankDetailsUseCase())
    ..registerLazySingleton(() => ContractorSaveBankDetailsUseCase(getIt()))
    ..registerFactory(
      () => ContractorBankDetailsBloc(getIt(), getIt(), getIt()),
    );

  // The reminder to add the bank details opens this screen
  // (ARCHITECTURE.md §13).
  AppNotificationLinks.register(
    'bank_details_missing',
    (_) => (
      name: ContractorPaymentsRoutes.bankDetailsName,
      pathParameters: const {},
    ),
  );
}
