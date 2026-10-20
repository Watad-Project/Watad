import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

/// Marks the given notifications read; null marks all of them.
class MarkNotificationsReadUseCase implements UseCase<void, List<String>?> {
  const MarkNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<void>> call(List<String>? params) =>
      _repository.markRead(params);
}
