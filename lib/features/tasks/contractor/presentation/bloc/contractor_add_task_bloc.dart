import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_new_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_create_task_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';

part 'contractor_add_task_event.dart';
part 'contractor_add_task_state.dart';

/// Manages the contractor's add-task screen (`/contractor/tasks/:projectId/new`,
/// GRA-38): loads the contract project and existing tasks to compute the
/// remaining contract budget, validates form fields, and inserts the proposed
/// task.
class ContractorAddTaskBloc
    extends Bloc<ContractorAddTaskEvent, ContractorAddTaskState> {
  ContractorAddTaskBloc(this._getProject, this._getTasks, this._createTask)
    : super(const ContractorAddTaskState()) {
    on<ContractorAddTaskStarted>(_onStarted);
    on<ContractorAddTaskStartDateChanged>(_onStartDateChanged);
    on<ContractorAddTaskSubmitted>(_onSubmitted);
  }

  final ContractorGetTaskProjectUseCase _getProject;
  final ContractorGetProjectTasksUseCase _getTasks;
  final ContractorCreateTaskUseCase _createTask;

  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,2})?$');

  Future<void> _onStarted(
    ContractorAddTaskStarted event,
    Emitter<ContractorAddTaskState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ContractorAddTaskStatus.loading,
        loadFailure: () => null,
      ),
    );
    final (projectResult, tasksResult) = await (
      _getProject(event.projectId),
      _getTasks(event.projectId),
    ).wait;

    switch ((projectResult, tasksResult)) {
      case (Success(data: final project), Success(data: final tasks)):
        emit(
          state.copyWith(
            status: ContractorAddTaskStatus.ready,
            project: project,
            tasks: tasks,
            loadFailure: () => null,
          ),
        );
      case (Failed(:final failure), _) || (_, Failed(:final failure)):
        emit(
          state.copyWith(
            status: ContractorAddTaskStatus.failure,
            loadFailure: () => failure,
          ),
        );
    }
  }

  void _onStartDateChanged(
    ContractorAddTaskStartDateChanged event,
    Emitter<ContractorAddTaskState> emit,
  ) {
    emit(state.copyWith(startDate: () => event.startDate));
  }

  Future<void> _onSubmitted(
    ContractorAddTaskSubmitted event,
    Emitter<ContractorAddTaskState> emit,
  ) async {
    if (state.isSubmitting) return;

    final project = state.project;
    if (project != null && !project.isInProgress) {
      emit(
        state.copyWith(
          submissionFailure: () => const ValidationFailure(
            'tasks.contractor.add_error_not_in_progress',
          ),
        ),
      );
      return;
    }

    final trimmedTitle = event.title.trim();
    final trimmedDescription = event.description.trim();
    final trimmedAmount = event.rawAmount.trim();

    String? titleError;
    if (trimmedTitle.isEmpty) {
      titleError = 'tasks.contractor.add_error_title_required';
    } else if (trimmedTitle.length < 2 || trimmedTitle.length > 150) {
      titleError = 'tasks.contractor.add_error_title_length';
    }

    String? descriptionError;
    if (trimmedDescription.isEmpty) {
      descriptionError = 'tasks.contractor.add_error_description_required';
    } else if (trimmedDescription.length > 5000) {
      descriptionError = 'tasks.contractor.add_error_description_length';
    }

    String? amountError;
    Money? parsedAmount;
    if (trimmedAmount.isNotEmpty) {
      final normalized = _normalizeNumber(trimmedAmount);
      final numericValue = _amountPattern.hasMatch(normalized)
          ? double.tryParse(normalized)
          : null;
      if (numericValue == null || numericValue <= 0) {
        amountError = 'tasks.contractor.add_error_amount_invalid';
      } else {
        final candidate = Money.fromSar(numericValue);
        if (candidate <= const Money.zero()) {
          amountError = 'tasks.contractor.add_error_amount_invalid';
        } else {
          final remaining = state.amountLeft;
          if (remaining != null && candidate > remaining) {
            amountError = 'tasks.contractor.add_error_amount_exceeds_remaining';
          } else {
            parsedAmount = candidate;
          }
        }
      }
    }

    if (titleError != null || descriptionError != null || amountError != null) {
      emit(
        state.copyWith(
          titleErrorKey: () => titleError,
          descriptionErrorKey: () => descriptionError,
          amountErrorKey: () => amountError,
          submissionFailure: () => null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        titleErrorKey: () => null,
        descriptionErrorKey: () => null,
        amountErrorKey: () => null,
        submissionFailure: () => null,
      ),
    );

    final result = await _createTask(
      ContractorNewTask(
        projectId: event.projectId,
        title: trimmedTitle,
        description: trimmedDescription,
        amount: parsedAmount,
        startDate: state.startDate,
      ),
    );

    switch (result) {
      case Success():
        emit(state.copyWith(isSubmitting: false, isSubmitted: true));
      case Failed(:final failure):
        emit(
          state.copyWith(isSubmitting: false, submissionFailure: () => failure),
        );
    }
  }

  /// Normalizes Arabic-Indic digits and separators into standard ASCII digits
  /// and a decimal dot.
  static String _normalizeNumber(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
      } else if (rune == 0x066B) {
        buffer.write('.');
      } else if (rune == 0x002C || rune == 0x066C || rune == 0x0020) {
        // Ignore thousand separators and spaces.
        continue;
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
