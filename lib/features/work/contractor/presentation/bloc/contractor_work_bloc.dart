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
  ContractorWorkOverview? _unfilteredOverview;

  Future<void> _onStarted(
    ContractorWorkStarted event,
    Emitter<ContractorWorkState> emit,
  ) async {
    _selectedTabIndex = 0;
    _selectedContractFilterIndex = 0;
    _filter = const ContractorWorkFilter();
    _unfilteredOverview = null;
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
    _emitFiltered(emit);
  }

  void _onContractFilterChanged(
    ContractorWorkContractFilterChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    _selectedContractFilterIndex = event.filterIndex;
    _emitFiltered(emit);
  }

  void _onSearchQueryChanged(
    ContractorWorkSearchQueryChanged event,
    Emitter<ContractorWorkState> emit,
  ) {
    _filter = _filter.copyWith(searchQuery: event.searchQuery);
    _emitFiltered(emit);
  }

  void _onFilterUpdated(
    ContractorWorkFilterUpdated event,
    Emitter<ContractorWorkState> emit,
  ) {
    _filter = event.filter;
    _emitFiltered(emit);
  }

  void _onFilterReset(
    ContractorWorkFilterReset event,
    Emitter<ContractorWorkState> emit,
  ) {
    _filter = const ContractorWorkFilter();
    _emitFiltered(emit);
  }

  void _emitFiltered(Emitter<ContractorWorkState> emit) {
    final raw = _unfilteredOverview;
    if (raw == null) return;
    final filteredOpenProjects = _filter.apply(raw.openProjects);
    final displayedOverview = ContractorWorkOverview(
      openProjects: filteredOpenProjects,
      contracts: raw.contracts,
    );
    emit(
      ContractorWorkLoadSuccess(
        overview: displayedOverview,
        selectedTabIndex: _selectedTabIndex,
        selectedContractFilterIndex: _selectedContractFilterIndex,
        filter: _filter,
      ),
    );
  }

  Future<void> _loadOverview(Emitter<ContractorWorkState> emit) async {
    final requestId = ++_requestId;
    final result = await _getWorkOverview(const ContractorWorkFilter());
    if (requestId != _requestId) return;
    switch (result) {
      case Success(:final data):
        _unfilteredOverview = data;
        _emitFiltered(emit);
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
