import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Where each tapped push leads.
class WatchNotificationTapsUseCase
    implements UseCase<Stream<Result<NotificationTarget>>, NoParams> {
  const WatchNotificationTapsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<Stream<Result<NotificationTarget>>>> call(
    NoParams params,
  ) async => Success(_repository.watchTaps());
}
