import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/router/routes/admin_blockchain_routes.dart';
import 'package:watad/features/blockchain/admin/datasource/remote/admin_blockchain_remote_data_source.dart';
import 'package:watad/features/blockchain/admin/datasource/repositories/admin_blockchain_repository_impl.dart';
import 'package:watad/features/blockchain/admin/domain/repositories/admin_blockchain_repository.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_check_blockchain_health_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_overview_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_project_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_resync_blockchain_project_use_case.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/bloc/admin_blockchain_project_bloc.dart';
import 'package:watad/features/blockchain/admin/presentation/widgets/admin_blockchain_tab.dart';

/// Registers everything in lib/features/blockchain/admin/.
void registerAdminBlockchainDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<AdminBlockchainRemoteDataSource>(
      () => AdminBlockchainRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AdminBlockchainRepository>(
      () => AdminBlockchainRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => AdminGetBlockchainOverviewUseCase(getIt()))
    ..registerLazySingleton(() => AdminGetBlockchainProjectUseCase(getIt()))
    ..registerLazySingleton(() => AdminCheckBlockchainHealthUseCase(getIt()))
    ..registerLazySingleton(() => AdminResyncBlockchainProjectUseCase(getIt()))
    ..registerFactory(() => AdminBlockchainBloc(getIt(), getIt()))
    ..registerFactory(() => AdminBlockchainProjectBloc(getIt(), getIt()))
    // The admin's navigation shows this as its «البلوك تشين» tab; the tab
    // reads the monitor and checks the ledger each time it shows.
    ..registerFactory<Widget>(
      () => AdminBlockchainTab(
        bloc: getIt<AdminBlockchainBloc>(),
        bell: AppSlots.widget(getIt, AppSlots.notificationsBell),
      ),
      instanceName: AdminBlockchainRoutes.blockchainName,
    );
}
