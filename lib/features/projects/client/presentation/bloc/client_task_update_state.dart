part of 'client_task_update_bloc.dart';

enum ClientTaskUpdateStatus { initial, loading, success, failure }

/// A message to show once after accepting, as a translation key.
final class ClientTaskUpdateMessage {
  const ClientTaskUpdateMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class ClientTaskUpdateState {
  const ClientTaskUpdateState({
    this.status = ClientTaskUpdateStatus.initial,
    this.update,
    this.failure,
    this.isAccepting = false,
    this.message,
  });

  final ClientTaskUpdateStatus status;
  final ClientTaskUpdate? update;

  /// Why the page couldn't load.
  final Failure? failure;
  final bool isAccepting;
  final ClientTaskUpdateMessage? message;

  ClientTaskUpdateState copyWith({
    ClientTaskUpdateStatus? status,
    ClientTaskUpdate? update,
    Failure? Function()? failure,
    bool? isAccepting,
    ClientTaskUpdateMessage? Function()? message,
  }) {
    return ClientTaskUpdateState(
      status: status ?? this.status,
      update: update ?? this.update,
      failure: failure == null ? this.failure : failure(),
      isAccepting: isAccepting ?? this.isAccepting,
      message: message == null ? this.message : message(),
    );
  }
}
