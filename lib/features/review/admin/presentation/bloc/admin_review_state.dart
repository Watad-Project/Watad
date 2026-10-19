part of 'admin_review_bloc.dart';

enum AdminReviewStatus { initial, loading, success, failure }

/// The filter chips. Deeds have no backend yet, so their list is empty.
enum AdminReviewFilter { all, license, deed }

/// A message to show once after a decision, as a translation key.
final class AdminReviewMessage {
  const AdminReviewMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminReviewState {
  const AdminReviewState({
    this.status = AdminReviewStatus.initial,
    this.requests = const [],
    this.filter = AdminReviewFilter.all,
    this.failure,
    this.busyBusinessId,
    this.message,
  });

  final AdminReviewStatus status;

  /// Pending license requests, oldest first.
  final List<AdminReviewRequest> requests;
  final AdminReviewFilter filter;

  /// Why the queue couldn't load.
  final Failure? failure;

  /// The request whose decision is being sent.
  final String? busyBusinessId;
  final AdminReviewMessage? message;

  /// The requests under the selected chip.
  List<AdminReviewRequest> get visible =>
      filter == AdminReviewFilter.deed ? const [] : requests;

  int get licenseCount => requests.length;

  /// Every pending request: today only licenses.
  int get allCount => licenseCount;

  AdminReviewState copyWith({
    AdminReviewStatus? status,
    List<AdminReviewRequest>? requests,
    AdminReviewFilter? filter,
    Failure? Function()? failure,
    String? Function()? busyBusinessId,
    AdminReviewMessage? Function()? message,
  }) {
    return AdminReviewState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      failure: failure == null ? this.failure : failure(),
      busyBusinessId: busyBusinessId == null
          ? this.busyBusinessId
          : busyBusinessId(),
      message: message == null ? this.message : message(),
    );
  }
}
