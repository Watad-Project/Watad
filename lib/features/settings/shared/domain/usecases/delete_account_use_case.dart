import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';

/// Closes the account, then signs out. The database refuses while an order
/// is paid or shipped, or a project is in progress, with messages the app
/// can't tell apart; so those are checked first, to say which one stops it.
class DeleteAccountUseCase implements UseCase<void, NoParams> {
  const DeleteAccountUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) async {
    final blockers = await _repository.getDeleteBlockers();
    switch (blockers) {
      case Failed(:final failure):
        return Failed(failure);
      case Success(:final data)
          when data.contains(SettingsDeleteBlocker.activeProjects):
        return const Failed(
          ValidationFailure('settings.delete_blocked_projects'),
        );
      case Success(:final data)
          when data.contains(SettingsDeleteBlocker.activeOrders):
        return const Failed(
          ValidationFailure('settings.delete_blocked_orders'),
        );
      case Success():
        break;
    }
    final deleted = await _repository.deleteAccount();
    if (deleted case Failed(:final failure)) return Failed(failure);
    return _repository.signOut();
  }
}
