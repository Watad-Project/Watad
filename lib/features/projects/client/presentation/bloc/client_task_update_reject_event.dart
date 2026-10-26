part of 'client_task_update_reject_bloc.dart';

sealed class ClientTaskUpdateRejectEvent {
  const ClientTaskUpdateRejectEvent();
}

/// «إرسال الرفض للمقاول», with a reason picked and the details written.
final class ClientTaskUpdateRejectSubmitted
    extends ClientTaskUpdateRejectEvent {
  const ClientTaskUpdateRejectSubmitted({
    required this.updateId,
    required this.reason,
    required this.details,
  });

  final String updateId;

  /// The reason as the client read it, already in their language.
  final String reason;
  final String details;
}
