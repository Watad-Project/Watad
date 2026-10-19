import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor_filter.dart';
import 'package:watad/features/home/client/domain/entities/client_contractors_query.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_contractors_use_case.dart';

part 'client_contractors_event.dart';
part 'client_contractors_state.dart';

/// «الكل»: every verified contractor, best rated first, a page at a time,
/// narrowed by name and rating.
class ClientContractorsBloc
    extends Bloc<ClientContractorsEvent, ClientContractorsState> {
  ClientContractorsBloc(this._getContractors)
    : super(const ClientContractorsState()) {
    on<ClientContractorsFetched>(
      (event, emit) => _loadFirstPage(state.filter, emit),
    );
    on<ClientContractorsFilterChanged>((event, emit) {
      if (event.filter == state.filter) return null;
      return _loadFirstPage(event.filter, emit);
    });
    on<ClientContractorsMoreRequested>(_onMoreRequested);
  }

  final ClientGetContractorsUseCase _getContractors;

  /// Contractors per page.
  static const int pageSize = 20;

  Future<void> _loadFirstPage(
    ClientContractorFilter filter,
    Emitter<ClientContractorsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClientContractorsStatus.loading,
        filter: filter,
        contractors: const [],
        hasMore: true,
        isLoadingMore: false,
      ),
    );
    final result = await _getContractors(
      ClientContractorsQuery(filter: filter, offset: 0, limit: pageSize),
    );
    // A newer filter replaced this one while it loaded.
    if (state.filter != filter) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientContractorsStatus.success,
            contractors: data,
            hasMore: data.length == pageSize,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientContractorsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onMoreRequested(
    ClientContractorsMoreRequested event,
    Emitter<ClientContractorsState> emit,
  ) async {
    if (state.status != ClientContractorsStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final filter = state.filter;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getContractors(
      ClientContractorsQuery(
        filter: filter,
        offset: state.contractors.length,
        limit: pageSize,
      ),
    );
    if (state.filter != filter) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            contractors: [...state.contractors, ...data],
            hasMore: data.length == pageSize,
            isLoadingMore: false,
          ),
        );
      case Failed():
        // The list stays; scrolling to the end again retries.
        emit(state.copyWith(isLoadingMore: false));
    }
  }
}
