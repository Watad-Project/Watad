import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/reviews/shared/datasource/remote/reviews_remote_data_source.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_draft.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';
import 'package:watad/features/reviews/shared/domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  const ReviewsRepositoryImpl(this._remote);

  final ReviewsRemoteDataSource _remote;

  @override
  Future<Result<ReviewDraft>> getDraft(ReviewSubject subject) =>
      guardSupabaseCall(() => _remote.getDraft(subject));

  @override
  Future<Result<void>> save(ReviewInput input) =>
      guardSupabaseCall(() => _remote.save(input));
}
