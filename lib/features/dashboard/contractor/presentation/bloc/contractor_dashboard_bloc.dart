import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';

part 'contractor_dashboard_event.dart';
part 'contractor_dashboard_state.dart';

class ContractorDashboardBloc
    extends Bloc<ContractorDashboardEvent, ContractorDashboardState> {
  ContractorDashboardBloc(this._getDashboardData)
    : super(const ContractorDashboardInitial()) {
    on<ContractorDashboardFetched>(_onFetched);
    on<ContractorDashboardRefreshed>(_onRefreshed);
  }

  final ContractorGetDashboardDataUseCase _getDashboardData;

  Future<void> _onFetched(
    ContractorDashboardFetched event,
    Emitter<ContractorDashboardState> emit,
  ) async {
    emit(const ContractorDashboardLoadInProgress());
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    ContractorDashboardRefreshed event,
    Emitter<ContractorDashboardState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<ContractorDashboardState> emit) async {
    final result = await _getDashboardData(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(ContractorDashboardLoadSuccess(data));
      case Failed(:final failure):
        // debugPrint('Dashboard Error: $e');
        log(
          'Dashboard Error: ${failure.cause ?? failure.messageKey}',
          name: 'watad.dashboard',
          error: failure.cause,
        );
        emit(ContractorDashboardLoadFailure(failure));
    }
  }
}
