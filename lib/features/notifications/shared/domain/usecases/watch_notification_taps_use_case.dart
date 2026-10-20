import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Each push the user taps.
class WatchNotificationTapsUseCase
    implements UseCase<Stream<Result<NotificationTap>>, NoParams> {
  const WatchNotificationTapsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<Stream<Result<NotificationTap>>>> call(NoParams params) async =>
      Success(_repository.watchTaps());
}
