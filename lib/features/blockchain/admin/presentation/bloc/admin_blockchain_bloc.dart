import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_filter.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_health.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overall.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_overview.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_uptime.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_check_blockchain_health_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_overview_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_uptime_use_case.dart';

part 'admin_blockchain_event.dart';
part 'admin_blockchain_state.dart';

/// The monitor: the ledger's health, its uptime (GRA-75), the sync summary
/// and the projects. The health check asks the blockchain itself and the
/// uptime has its own read, so both run beside the overview and never hold
/// it up; either failing leaves the rest on screen.
class AdminBlockchainBloc
    extends Bloc<AdminBlockchainEvent, AdminBlockchainState> {
  AdminBlockchainBloc(this._getOverview, this._checkHealth, this._getUptime)
    : super(const AdminBlockchainState()) {
    on<AdminBlockchainFetched>(_onFetched);
    on<AdminBlockchainHealthChecked>((event, emit) => _check(emit));
    on<AdminBlockchainFilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
  }

  final AdminGetBlockchainOverviewUseCase _getOverview;
  final AdminCheckBlockchainHealthUseCase _checkHealth;
  final AdminGetBlockchainUptimeUseCase _getUptime;

  Future<void> _onFetched(
    AdminBlockchainFetched event,
    Emitter<AdminBlockchainState> emit,
  ) async {
    emit(state.copyWith(status: AdminBlockchainStatus.loading));
    final health = _check(emit);
    final uptime = _loadUptime(emit);
    final result = await _getOverview(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminBlockchainStatus.success,
            overview: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminBlockchainStatus.failure,
            failure: () => failure,
          ),
        );
    }
    await health;
    await uptime;
  }

  /// The uptime, on every load; kept on screen while it loads again.
  Future<void> _loadUptime(Emitter<AdminBlockchainState> emit) async {
    emit(state.copyWith(uptimeStatus: AdminBlockchainUptimeStatus.loading));
    final result = await _getUptime(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            uptimeStatus: AdminBlockchainUptimeStatus.success,
            uptime: () => data,
            uptimeFailure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            uptimeStatus: AdminBlockchainUptimeStatus.failure,
            uptimeFailure: () => failure,
          ),
        );
    }
  }

  /// «فحص الآن», and every load. A check already running isn't repeated.
  Future<void> _check(Emitter<AdminBlockchainState> emit) async {
    if (state.healthStatus == AdminBlockchainHealthStatus.checking) return;
    emit(state.copyWith(healthStatus: AdminBlockchainHealthStatus.checking));
    final result = await _checkHealth(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            healthStatus: AdminBlockchainHealthStatus.success,
            health: () => data,
            healthFailure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            healthStatus: AdminBlockchainHealthStatus.failure,
            healthFailure: () => failure,
          ),
        );
    }
  }
}
