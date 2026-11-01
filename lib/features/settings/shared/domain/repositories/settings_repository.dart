import 'package:watad/core/error/result.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';

abstract interface class SettingsRepository {
  Future<Result<SettingsOverview>> getOverview();

  Future<Result<void>> setNotification(SettingsNotificationChange change);

  /// What would stop the account from closing now; empty when nothing does.
  Future<Result<Set<SettingsDeleteBlocker>>> getDeleteBlockers();

  /// `delete_my_account()`: the account is anonymised.
  Future<Result<void>> deleteAccount();

  /// Offline, then signed out.
  Future<Result<void>> signOut();
}
