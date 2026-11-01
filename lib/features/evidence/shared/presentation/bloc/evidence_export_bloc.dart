import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';
import 'package:watad/features/evidence/shared/domain/usecases/export_project_evidence_use_case.dart';

part 'evidence_export_event.dart';
part 'evidence_export_state.dart';

/// One project's signed evidence, collected from the database and the
/// blockchain by the server. The page makes the PDF from it.
class EvidenceExportBloc
    extends Bloc<EvidenceExportEvent, EvidenceExportState> {
  EvidenceExportBloc(this._export) : super(const EvidenceExportInitial()) {
    on<EvidenceExportStarted>(_onStarted);
  }

  final ExportProjectEvidenceUseCase _export;

  Future<void> _onStarted(
    EvidenceExportStarted event,
    Emitter<EvidenceExportState> emit,
  ) async {
    emit(const EvidenceExportLoadInProgress());
    final result = await _export(event.projectId);
    emit(switch (result) {
      Success(:final data) => EvidenceExportLoadSuccess(data),
      Failed(:final failure) => EvidenceExportLoadFailure(failure),
    });
  }
}
