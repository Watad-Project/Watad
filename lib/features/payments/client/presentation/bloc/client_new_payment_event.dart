part of 'client_new_payment_bloc.dart';

sealed class ClientNewPaymentEvent {
  const ClientNewPaymentEvent();
}

/// The page opened, the client pulled to refresh or tapped retry, or came
/// back from the transfer without sending.
final class ClientNewPaymentFetched extends ClientNewPaymentEvent {
  const ClientNewPaymentFetched(this.projectId);

  final String projectId;
}

/// A task was ticked or unticked.
final class ClientNewPaymentTaskToggled extends ClientNewPaymentEvent {
  const ClientNewPaymentTaskToggled(this.taskId);

  final String taskId;
}
