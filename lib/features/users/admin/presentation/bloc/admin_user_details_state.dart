part of 'admin_user_details_bloc.dart';

enum AdminUserDetailsStatus { initial, loading, success, failure }

/// A message to show once after an action, as a translation key.
final class AdminUserDetailsMessage {
  const AdminUserDetailsMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminUserDetailsState {
  const AdminUserDetailsState({
    this.status = AdminUserDetailsStatus.initial,
    this.userId,
    this.user,
    this.failure,
    this.isBusy = false,
    this.message,
  });

  final AdminUserDetailsStatus status;

  /// The user the page shows, from the route.
  final String? userId;
  final AdminUser? user;

  /// Why the user couldn't load; [NotFoundFailure] when there is none.
  final Failure? failure;

  /// An action is being sent.
  final bool isBusy;
  final AdminUserDetailsMessage? message;

  AdminUserDetailsState copyWith({
    AdminUserDetailsStatus? status,
    String? userId,
    AdminUser? Function()? user,
    Failure? Function()? failure,
    bool? isBusy,
    AdminUserDetailsMessage? Function()? message,
  }) {
    return AdminUserDetailsState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      user: user == null ? this.user : user(),
      failure: failure == null ? this.failure : failure(),
      isBusy: isBusy ?? this.isBusy,
      message: message == null ? this.message : message(),
    );
  }
}
