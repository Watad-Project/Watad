part of 'client_project_deed_bloc.dart';

enum ClientProjectDeedStatus { initial, loading, ready, failure }

final class ClientProjectDeedState {
  const ClientProjectDeedState({
    this.status = ClientProjectDeedStatus.initial,
    this.project,
    this.failure,
    this.filePath,
    this.fileName,
    this.isSending = false,
    this.isSent = false,
    this.errorKey,
  });

  final ClientProjectDeedStatus status;
  final ClientProject? project;

  /// Why the project couldn't load.
  final Failure? failure;

  /// The new deed on the device, once picked.
  final String? filePath;
  final String? fileName;
  final bool isSending;

  /// Sent: the deed is back under review, and the page closes.
  final bool isSent;

  /// Why sending failed, as a translation key, to show once.
  final String? errorKey;

  ClientProjectDeedState copyWith({
    ClientProjectDeedStatus? status,
    ClientProject? Function()? project,
    Failure? Function()? failure,
    String? Function()? filePath,
    String? Function()? fileName,
    bool? isSending,
    bool? isSent,
    String? Function()? errorKey,
  }) {
    return ClientProjectDeedState(
      status: status ?? this.status,
      project: project == null ? this.project : project(),
      failure: failure == null ? this.failure : failure(),
      filePath: filePath == null ? this.filePath : filePath(),
      fileName: fileName == null ? this.fileName : fileName(),
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      errorKey: errorKey == null ? this.errorKey : errorKey(),
    );
  }
}
