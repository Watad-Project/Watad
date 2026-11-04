import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/domain/usecases/get_my_reports_use_case.dart';

part 'support_reports_event.dart';
part 'support_reports_state.dart';

/// «المساعدة والدعم» (GRA-63): my reports and where each stands.
class SupportReportsBloc
    extends Bloc<SupportReportsEvent, SupportReportsState> {
  SupportReportsBloc(this._getReports) : super(const SupportReportsInitial()) {
    on<SupportReportsFetched>(_onFetched);
  }

  final GetMyReportsUseCase _getReports;

  Future<void> _onFetched(
    SupportReportsFetched event,
    Emitter<SupportReportsState> emit,
  ) async {
    emit(const SupportReportsLoadInProgress());
    final result = await _getReports(const NoParams());
    emit(switch (result) {
      Success(:final data) => SupportReportsLoadSuccess(data),
      Failed(:final failure) => SupportReportsLoadFailure(failure),
    });
  }
}
