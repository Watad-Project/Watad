import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';
import 'package:watad/features/evidence/shared/domain/usecases/get_contracted_projects_use_case.dart';

part 'evidence_projects_event.dart';
part 'evidence_projects_state.dart';

/// «تصدير سجل مشروع»: my contracted projects, to pick one to export.
class EvidenceProjectsBloc
    extends Bloc<EvidenceProjectsEvent, EvidenceProjectsState> {
  EvidenceProjectsBloc(this._getProjects)
    : super(const EvidenceProjectsInitial()) {
    on<EvidenceProjectsFetched>(_onFetched);
  }

  final GetContractedProjectsUseCase _getProjects;

  Future<void> _onFetched(
    EvidenceProjectsFetched event,
    Emitter<EvidenceProjectsState> emit,
  ) async {
    emit(const EvidenceProjectsLoadInProgress());
    final result = await _getProjects(const NoParams());
    emit(switch (result) {
      Success(:final data) => EvidenceProjectsLoadSuccess(data),
      Failed(:final failure) => EvidenceProjectsLoadFailure(failure),
    });
  }
}
