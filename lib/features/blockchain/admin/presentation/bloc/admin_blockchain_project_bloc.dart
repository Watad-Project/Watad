import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_project.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_get_blockchain_project_use_case.dart';
import 'package:watad/features/blockchain/admin/domain/usecases/admin_resync_blockchain_project_use_case.dart';

part 'admin_blockchain_project_event.dart';
part 'admin_blockchain_project_state.dart';

/// One project's sync, and «إعادة المزامنة الآن». After the resync the
/// project is read again, so its state comes from the server.
class AdminBlockchainProjectBloc
    extends Bloc<AdminBlockchainProjectEvent, AdminBlockchainProjectState> {
  AdminBlockchainProjectBloc(this._getProject, this._resync)
    : super(const AdminBlockchainProjectState()) {
    on<AdminBlockchainProjectFetched>(_onFetched);
    on<AdminBlockchainProjectResynced>(_onResynced);
  }

  final AdminGetBlockchainProjectUseCase _getProject;
  final AdminResyncBlockchainProjectUseCase _resync;

  Future<void> _onFetched(
    AdminBlockchainProjectFetched event,
    Emitter<AdminBlockchainProjectState> emit,
  ) async {
    emit(state.copyWith(projectId: () => event.projectId, failure: () => null));
    final result = await _getProject(event.projectId);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(project: () => data, failure: () => null));
      case Failed(:final failure):
        emit(state.copyWith(failure: () => failure));
    }
  }

  Future<void> _onResynced(
    AdminBlockchainProjectResynced event,
    Emitter<AdminBlockchainProjectState> emit,
  ) async {
    final projectId = state.projectId;
    if (projectId == null || state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    final result = await _resync(projectId);
    // Also after a failure: the project may have changed meanwhile.
    final project = await _getProject(projectId);
    emit(
      state.copyWith(
        project: project is Success<AdminBlockchainProject>
            ? () => project.data
            : null,
        isBusy: false,
        message: () => switch (result) {
          Success() => const AdminBlockchainProjectMessage(
            'blockchain.admin.resync_sent',
            isError: false,
          ),
          Failed(:final failure) => AdminBlockchainProjectMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }
}
