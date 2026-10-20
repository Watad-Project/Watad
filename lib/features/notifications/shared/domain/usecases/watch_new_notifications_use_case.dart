import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Each new notification as it arrives, while the app is open.
class WatchNewNotificationsUseCase
    implements UseCase<Stream<Result<UserNotification>>, NoParams> {
  const WatchNewNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<Stream<Result<UserNotification>>>> call(
    NoParams params,
  ) async => Success(_repository.watchNew());
}
