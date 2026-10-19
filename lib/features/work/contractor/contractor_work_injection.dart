import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/features/work/contractor/datasource/remote/contractor_work_remote_data_source.dart';
import 'package:watad/features/work/contractor/datasource/repositories/contractor_work_repository_impl.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_edit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_bid_details_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_my_contracts_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_submit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_withdraw_offer_use_case.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_work_tab.dart';

void registerContractorWorkDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ContractorWorkRemoteDataSource>(
      () => ContractorWorkRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ContractorWorkRepository>(
      () => ContractorWorkRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => ContractorGetWorkOverviewUseCase(getIt()))
    ..registerLazySingleton(() => ContractorGetMyContractsUseCase(getIt()))
    ..registerLazySingleton(() => ContractorGetBidDetailsUseCase(getIt()))
    ..registerLazySingleton(() => ContractorSubmitOfferUseCase(getIt()))
    ..registerLazySingleton(() => ContractorEditOfferUseCase(getIt()))
    ..registerLazySingleton(() => ContractorWithdrawOfferUseCase(getIt()))
    ..registerFactory(() => ContractorWorkBloc(getIt()))
    ..registerFactory(
      () => ContractorBidBloc(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<Widget>(
      () => ContractorWorkTab(
        bloc: getIt<ContractorWorkBloc>()..add(const ContractorWorkStarted()),
      ),
      instanceName: ContractorWorkRoutes.workName,
    );
}
