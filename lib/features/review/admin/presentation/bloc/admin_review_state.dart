part of 'admin_review_bloc.dart';

enum AdminReviewStatus { initial, loading, success, failure }

/// The filter chips.
enum AdminReviewFilter { all, license, deed }

final class AdminReviewState {
  const AdminReviewState({
    this.status = AdminReviewStatus.initial,
    this.requests = const [],
    this.filter = AdminReviewFilter.all,
    this.failure,
  });

  final AdminReviewStatus status;

  /// Pending licenses and deeds, oldest first.
  final List<AdminReviewRequest> requests;
  final AdminReviewFilter filter;

  /// Why the queue couldn't load.
  final Failure? failure;

  /// The requests under the selected chip.
  List<AdminReviewRequest> get visible => switch (filter) {
    AdminReviewFilter.all => requests,
    AdminReviewFilter.license => _of(AdminReviewKind.license),
    AdminReviewFilter.deed => _of(AdminReviewKind.deed),
  };

  int get allCount => requests.length;

  int get licenseCount => _of(AdminReviewKind.license).length;

  int get deedCount => _of(AdminReviewKind.deed).length;

  List<AdminReviewRequest> _of(AdminReviewKind kind) => [
    for (final request in requests)
      if (request.kind == kind) request,
  ];

  AdminReviewState copyWith({
    AdminReviewStatus? status,
    List<AdminReviewRequest>? requests,
    AdminReviewFilter? filter,
    Failure? Function()? failure,
  }) {
    return AdminReviewState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
