import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';

/// «تسجيل الخروج». Push signs the phone out of OneSignal by itself when
/// the session ends (ARCHITECTURE.md §13).
class SignOutUseCase implements UseCase<void, NoParams> {
  const SignOutUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}
