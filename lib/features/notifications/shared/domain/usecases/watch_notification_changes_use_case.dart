import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Each change to the user's notifications, live, while the app is open.
class WatchNotificationChangesUseCase
    implements UseCase<Stream<Result<UserNotificationChange>>, NoParams> {
  const WatchNotificationChangesUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<Stream<Result<UserNotificationChange>>>> call(
    NoParams params,
  ) async => Success(_repository.watchChanges());
}
