part of 'admin_review_details_bloc.dart';

enum AdminReviewDetailsStatus { initial, loading, success, failure }

/// Where the admin's decision stands. [done]: the page closes.
enum AdminReviewDecisionStatus { idle, sending, done }

/// A message to show once after a decision, as a translation key.
final class AdminReviewMessage {
  const AdminReviewMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminReviewDetailsState {
  const AdminReviewDetailsState({
    this.status = AdminReviewDetailsStatus.initial,
    this.details,
    this.failure,
    this.decision = AdminReviewDecisionStatus.idle,
    this.message,
  });

  final AdminReviewDetailsStatus status;

  /// The request, once loaded.
  final AdminReviewDetails? details;

  /// Why the request couldn't load.
  final Failure? failure;
  final AdminReviewDecisionStatus decision;
  final AdminReviewMessage? message;

  bool get isSending => decision == AdminReviewDecisionStatus.sending;

  AdminReviewDetailsState copyWith({
    AdminReviewDetailsStatus? status,
    AdminReviewDetails? Function()? details,
    Failure? Function()? failure,
    AdminReviewDecisionStatus? decision,
    AdminReviewMessage? Function()? message,
  }) {
    return AdminReviewDetailsState(
      status: status ?? this.status,
      details: details == null ? this.details : details(),
      failure: failure == null ? this.failure : failure(),
      decision: decision ?? this.decision,
      message: message == null ? this.message : message(),
    );
  }
}
