import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';

part 'contractor_work_event.dart';
part 'contractor_work_state.dart';

class ContractorWorkBloc
    extends Bloc<ContractorWorkEvent, ContractorWorkState> {
  ContractorWorkBloc(this._getWorkOverview)
    : super(const ContractorWorkInitial()) {
    on<ContractorWorkStarted>(_onStarted);
    on<ContractorWorkRefreshed>(_onRefreshed);
    on<ContractorWorkTabChanged>(_onTabChanged);
    on<ContractorWorkContractFilterChanged>(_onContractFilterChanged);
  }

  final ContractorGetWorkOverviewUseCase _getWorkOverview;

  Future<void> _onStarted(
    ContractorWorkStarted event,
    Emitter<ContractorWorkState> emit,
  ) async {
    emit(const ContractorWorkLoadInProgress());
    await _loadOverview(
      emit,
      selectedTabIndex: 0,
      selectedContractFilterIndex: 0,
    );
  }

  Future<void> _onRefreshed(
    ContractorWorkRefreshed event,
    Emitter<ContractorWorkState> emit,
  ) async {
    final (currentTabIndex, currentFilterIndex) = switch (state) {
      ContractorWorkLoadSuccess(
        :final selectedTabIndex,
        :final selectedContractFilterIndex,
      ) =>
        (selectedTabIndex, selectedContractFilterIndex),
      _ => (0, 0),
    };
    await _loadOverview(
      emit,
      selectedTabIndex: currentTabIndex,
      selectedContractFilterIndex: currentFilterIndex,
    );
  }

  void _onTabChanged(
    ContractorWorkTabChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    final current = state;
    if (current is ContractorWorkLoadSuccess) {
      emit(
        ContractorWorkLoadSuccess(
          overview: current.overview,
          selectedTabIndex: event.tabIndex,
          selectedContractFilterIndex: current.selectedContractFilterIndex,
        ),
      );
    }
  }

  void _onContractFilterChanged(
    ContractorWorkContractFilterChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    final current = state;
    if (current is ContractorWorkLoadSuccess) {
      emit(
        ContractorWorkLoadSuccess(
          overview: current.overview,
          selectedTabIndex: current.selectedTabIndex,
          selectedContractFilterIndex: event.filterIndex,
        ),
      );
    }
  }

  Future<void> _loadOverview(
    Emitter<ContractorWorkState> emit, {
    required int selectedTabIndex,
    required int selectedContractFilterIndex,
  }) async {
    final result = await _getWorkOverview(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          ContractorWorkLoadSuccess(
            overview: data,
            selectedTabIndex: selectedTabIndex,
            selectedContractFilterIndex: selectedContractFilterIndex,
          ),
        );
      case Failed(:final failure):
        log(
          'ContractorWork Error: ${failure.cause ?? failure.messageKey}',
          name: 'watad.work.contractor',
          error: failure.cause,
        );
        emit(ContractorWorkLoadFailure(failure));
    }
  }
}
