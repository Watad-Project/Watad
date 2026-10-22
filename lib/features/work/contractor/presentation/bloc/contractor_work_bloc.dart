import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
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
    on<ContractorWorkSearchQueryChanged>(_onSearchQueryChanged);
    on<ContractorWorkFilterUpdated>(_onFilterUpdated);
    on<ContractorWorkFilterReset>(_onFilterReset);
  }

  final ContractorGetWorkOverviewUseCase _getWorkOverview;

  int _selectedTabIndex = 0;
  int _selectedContractFilterIndex = 0;
  ContractorWorkFilter _filter = const ContractorWorkFilter();
  int _requestId = 0;

  Future<void> _onStarted(
    ContractorWorkStarted event,
    Emitter<ContractorWorkState> emit,
  ) async {
    _selectedTabIndex = 0;
    _selectedContractFilterIndex = 0;
    _filter = const ContractorWorkFilter();
    emit(const ContractorWorkLoadInProgress());
    await _loadOverview(emit);
  }

  Future<void> _onRefreshed(
    ContractorWorkRefreshed event,
    Emitter<ContractorWorkState> emit,
  ) async {
    await _loadOverview(emit);
  }

  void _onTabChanged(
    ContractorWorkTabChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    _selectedTabIndex = event.tabIndex;
    final current = state;
    if (current is ContractorWorkLoadSuccess) {
      emit(
        ContractorWorkLoadSuccess(
          overview: current.overview,
          selectedTabIndex: _selectedTabIndex,
          selectedContractFilterIndex: _selectedContractFilterIndex,
          filter: _filter,
        ),
      );
    }
  }

  void _onContractFilterChanged(
    ContractorWorkContractFilterChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    _selectedContractFilterIndex = event.filterIndex;
    final current = state;
    if (current is ContractorWorkLoadSuccess) {
      emit(
        ContractorWorkLoadSuccess(
          overview: current.overview,
          selectedTabIndex: _selectedTabIndex,
          selectedContractFilterIndex: _selectedContractFilterIndex,
          filter: _filter,
        ),
      );
    }
  }

  Future<void> _onSearchQueryChanged(
    ContractorWorkSearchQueryChanged event,
    Emitter<ContractorWorkState> emit,
  ) async {
    _filter = _filter.copyWith(searchQuery: event.searchQuery);
    await _loadOverview(emit);
  }

  Future<void> _onFilterUpdated(
    ContractorWorkFilterUpdated event,
    Emitter<ContractorWorkState> emit,
  ) async {
    _filter = event.filter;
    await _loadOverview(emit);
  }

  Future<void> _onFilterReset(
    ContractorWorkFilterReset event,
    Emitter<ContractorWorkState> emit,
  ) async {
    _filter = const ContractorWorkFilter();
    await _loadOverview(emit);
  }

  Future<void> _loadOverview(Emitter<ContractorWorkState> emit) async {
    final requestId = ++_requestId;
    final snapshotFilter = _filter;
    final result = await _getWorkOverview(snapshotFilter);
    if (requestId != _requestId) return;
    switch (result) {
      case Success(:final data):
        emit(
          ContractorWorkLoadSuccess(
            overview: data,
            selectedTabIndex: _selectedTabIndex,
            selectedContractFilterIndex: _selectedContractFilterIndex,
            filter: _filter,
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
