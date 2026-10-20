import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

class GetUnreadNotificationsCountUseCase implements UseCase<int, NoParams> {
  const GetUnreadNotificationsCountUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<int>> call(NoParams params) => _repository.getUnreadCount();
}
