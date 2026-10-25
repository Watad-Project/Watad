part of 'client_task_update_reject_bloc.dart';

final class ClientTaskUpdateRejectState {
  const ClientTaskUpdateRejectState({
    this.isSending = false,
    this.isSent = false,
    this.errorKey,
  });

  final bool isSending;

  /// The server took the rejection: the pages go back to the timeline.
  final bool isSent;

  /// Why sending failed, as a translation key.
  final String? errorKey;

  ClientTaskUpdateRejectState copyWith({
    bool? isSending,
    bool? isSent,
    String? Function()? errorKey,
  }) {
    return ClientTaskUpdateRejectState(
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      errorKey: errorKey == null ? this.errorKey : errorKey(),
    );
  }
}
