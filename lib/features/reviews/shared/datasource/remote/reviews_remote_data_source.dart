import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/reviews/shared/datasource/models/review_draft_model.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_input.dart';
import 'package:watad/features/reviews/shared/domain/entities/review_subject.dart';

abstract interface class ReviewsRemoteDataSource {
  /// The `v_public_profiles` name of whom I'm rating, and my `v_reviews`
  /// row for the same project or order.
  Future<ReviewDraftModel> getDraft(ReviewSubject subject);

  /// Inserts into `reviews` (target, project or order, rating, comment),
  /// or updates my row's rating and comment (ARCHITECTURE.md §3a).
  Future<void> save(ReviewInput input);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  const ReviewsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ReviewDraftModel> getDraft(ReviewSubject subject) async {
    final profile = await _client
        .from('v_public_profiles')
        .select('display_name')
        .eq('id', subject.targetUserId)
        .single();
    final mine = _client
        .from('v_reviews')
        .select('id, rating, comment')
        .eq('is_mine', true)
        .eq('target_user_id', subject.targetUserId);
    final review = await switch (subject) {
      ReviewSubject(:final projectId?) => mine.eq('project_id', projectId),
      ReviewSubject(:final orderId?) => mine.eq('order_id', orderId),
      // Neither: no review can match.
      _ => mine.isFilter('id', null),
    }.maybeSingle();
    return ReviewDraftModel.fromJson({...profile, 'my_review': review});
  }

  @override
  Future<void> save(ReviewInput input) async {
    final comment = input.comment.isEmpty ? null : input.comment;
    if (input.existingId case final id?) {
      await _client
          .from('reviews')
          .update({'rating': input.rating, 'comment': comment})
          .eq('id', id);
      return;
    }
    final subject = input.subject;
    await _client.from('reviews').insert({
      'target_user_id': subject.targetUserId,
      'project_id': ?subject.projectId,
      'order_id': ?subject.orderId,
      'rating': input.rating,
      'comment': comment,
    });
  }
}
