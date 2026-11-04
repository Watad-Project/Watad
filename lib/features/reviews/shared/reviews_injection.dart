import 'package:get_it/get_it.dart';
import 'package:watad/features/reviews/shared/datasource/remote/reviews_remote_data_source.dart';
import 'package:watad/features/reviews/shared/datasource/repositories/reviews_repository_impl.dart';
import 'package:watad/features/reviews/shared/domain/repositories/reviews_repository.dart';
import 'package:watad/features/reviews/shared/domain/usecases/get_review_draft_use_case.dart';
import 'package:watad/features/reviews/shared/domain/usecases/save_review_use_case.dart';
import 'package:watad/features/reviews/shared/presentation/bloc/write_review_bloc.dart';

/// Registers everything in lib/features/reviews/shared/.
void registerReviewsDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ReviewsRemoteDataSource>(
      () => ReviewsRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ReviewsRepository>(
      () => ReviewsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetReviewDraftUseCase(getIt()))
    ..registerLazySingleton(() => SaveReviewUseCase(getIt()))
    ..registerFactory(() => WriteReviewBloc(getIt(), getIt()));
}
