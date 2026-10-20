import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

class GetNotificationsUseCase
    implements UseCase<List<UserNotification>, NoParams> {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<List<UserNotification>>> call(NoParams params) =>
      _repository.getNotifications();
}
