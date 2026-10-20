import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Push on this device for the signed-in user.
class StartPushUseCase implements UseCase<void, NoParams> {
  const StartPushUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.startPush();
}
