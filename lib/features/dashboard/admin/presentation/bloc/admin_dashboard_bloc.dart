import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_section.dart';
import 'package:watad/features/dashboard/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:watad/features/dashboard/admin/domain/usecases/admin_get_dashboard_stats_use_case.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

/// The admin dashboard's numbers and the chip that picks which of them show.
/// A reload keeps the last numbers, and the chip, on screen.
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  AdminDashboardBloc(this._getStats) : super(const AdminDashboardState()) {
    on<AdminDashboardFetched>(_onFetched);
    on<AdminDashboardSectionChanged>(
      (event, emit) => emit(state.copyWith(section: event.section)),
    );
  }

  final AdminGetDashboardStatsUseCase _getStats;

  Future<void> _onFetched(
    AdminDashboardFetched event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(state.copyWith(status: AdminDashboardStatus.loading));
    final result = await _getStats(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminDashboardStatus.success,
            stats: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminDashboardStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
