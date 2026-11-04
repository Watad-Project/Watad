import 'package:get_it/get_it.dart';
import 'package:watad/features/support/shared/datasource/remote/support_remote_data_source.dart';
import 'package:watad/features/support/shared/datasource/repositories/support_repository_impl.dart';
import 'package:watad/features/support/shared/domain/repositories/support_repository.dart';
import 'package:watad/features/support/shared/domain/usecases/get_my_reports_use_case.dart';
import 'package:watad/features/support/shared/domain/usecases/send_report_use_case.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_new_report_bloc.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_reports_bloc.dart';

/// Registers everything in lib/features/support/shared/.
void registerSupportDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<SupportRemoteDataSource>(
      () => SupportRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<SupportRepository>(
      () => SupportRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetMyReportsUseCase(getIt()))
    ..registerLazySingleton(() => SendReportUseCase(getIt()))
    ..registerFactory(() => SupportReportsBloc(getIt()))
    ..registerFactory(() => SupportNewReportBloc(getIt()));
}
