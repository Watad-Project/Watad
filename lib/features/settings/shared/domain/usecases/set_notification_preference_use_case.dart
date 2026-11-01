import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';

/// Saves one switch of «الإشعارات» the moment it's tapped.
class SetNotificationPreferenceUseCase
    implements UseCase<void, SettingsNotificationChange> {
  const SetNotificationPreferenceUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<void>> call(SettingsNotificationChange change) =>
      _repository.setNotification(change);
}
