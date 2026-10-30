part of 'contractor_add_task_bloc.dart';

sealed class ContractorAddTaskEvent {
  const ContractorAddTaskEvent();
}

/// Dispatched when the add-task screen opens or when retrying after an initial
/// load failure.
final class ContractorAddTaskStarted extends ContractorAddTaskEvent {
  const ContractorAddTaskStarted(this.projectId);

  final String projectId;
}

/// Dispatched when the contractor picks or clears the optional start date.
final class ContractorAddTaskStartDateChanged extends ContractorAddTaskEvent {
  const ContractorAddTaskStartDateChanged(this.startDate);

  final DateTime? startDate;
}

/// Dispatched when the contractor taps «إرسال للعميل».
final class ContractorAddTaskSubmitted extends ContractorAddTaskEvent {
  const ContractorAddTaskSubmitted({
    required this.projectId,
    required this.title,
    required this.description,
    required this.rawAmount,
  });

  final String projectId;
  final String title;
  final String description;
  final String rawAmount;
}
