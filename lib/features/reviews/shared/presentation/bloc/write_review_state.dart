part of 'write_review_bloc.dart';

enum WriteReviewStatus { initial, loading, ready, failure, saved }

final class WriteReviewState {
  const WriteReviewState({
    this.status = WriteReviewStatus.initial,
    this.subject,
    this.draft,
    this.failure,
    this.isSaving = false,
    this.saveFailure,
  });

  final WriteReviewStatus status;

  /// From the route, so a retry knows what to load.
  final ReviewSubject? subject;
  final ReviewDraft? draft;

  /// Why the sheet couldn't load.
  final Failure? failure;
  final bool isSaving;

  /// Why the review wasn't saved; the form stays as it was.
  final Failure? saveFailure;

  WriteReviewState copyWith({
    WriteReviewStatus? status,
    bool? isSaving,
    Failure? Function()? saveFailure,
  }) {
    return WriteReviewState(
      status: status ?? this.status,
      subject: subject,
      draft: draft,
      failure: failure,
      isSaving: isSaving ?? this.isSaving,
      saveFailure: saveFailure == null ? this.saveFailure : saveFailure(),
    );
  }
}
