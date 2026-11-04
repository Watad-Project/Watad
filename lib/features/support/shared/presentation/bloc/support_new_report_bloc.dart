import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/usecases/send_report_use_case.dart';

part 'support_new_report_event.dart';
part 'support_new_report_state.dart';

/// «بلاغ جديد» (GRA-63): sends a report.
class SupportNewReportBloc
    extends Bloc<SupportNewReportEvent, SupportNewReportState> {
  SupportNewReportBloc(this._send) : super(const SupportNewReportState()) {
    on<SupportNewReportSubmitted>(_onSubmitted);
  }

  final SendReportUseCase _send;

  Future<void> _onSubmitted(
    SupportNewReportSubmitted event,
    Emitter<SupportNewReportState> emit,
  ) async {
    if (state.status == SupportNewReportStatus.sending) return;
    emit(const SupportNewReportState(status: SupportNewReportStatus.sending));
    final result = await _send(event.report);
    emit(switch (result) {
      Success() => const SupportNewReportState(
        status: SupportNewReportStatus.sent,
      ),
      Failed(:final failure) => SupportNewReportState(
        status: SupportNewReportStatus.failure,
        failure: failure,
      ),
    });
  }
}
