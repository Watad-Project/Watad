part of 'client_new_payment_bloc.dart';

enum ClientNewPaymentStatus { initial, loading, success, failure }

final class ClientNewPaymentState {
  const ClientNewPaymentState({
    this.status = ClientNewPaymentStatus.initial,
    this.tasks = const [],
    this.selectedIds = const {},
    this.total = const Money.zero(),
    this.failure,
  });

  final ClientNewPaymentStatus status;

  /// In timeline order, without the rejected ones.
  final List<ClientPaymentTask> tasks;

  /// The tasks the client selected to pay.
  final Set<String> selectedIds;

  /// What the selected tasks add up to.
  final Money total;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The selected tasks, in timeline order.
  List<ClientPaymentTask> get selectedTasks => [
    for (final task in tasks)
      if (selectedIds.contains(task.id)) task,
  ];

  bool get hasPayable =>
      tasks.any((task) => task.payability == ClientTaskPayability.payable);

  /// «متابعة» needs at least one task.
  bool get canContinue => selectedIds.isNotEmpty;

  ClientNewPaymentState copyWith({
    ClientNewPaymentStatus? status,
    List<ClientPaymentTask>? tasks,
    Set<String>? selectedIds,
    Money? total,
    Failure? Function()? failure,
  }) {
    return ClientNewPaymentState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      selectedIds: selectedIds ?? this.selectedIds,
      total: total ?? this.total,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
