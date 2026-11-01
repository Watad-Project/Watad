import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/notification_group.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';
import 'package:watad/features/settings/shared/settings_injection.dart';

/// A contractor without bank details, every group on.
const SettingsOverview fakeSettingsOverview = SettingsOverview(
  isContractor: true,
  hasBankDetails: false,
  notifications: {
    NotificationGroup.messages: true,
    NotificationGroup.projects: true,
    NotificationGroup.tasks: true,
    NotificationGroup.marketplace: true,
  },
);

/// A hand-written [SettingsRepository]: it answers with the results you set
/// and records every call, in order (APP_ARCHITECTURE.md §16).
class FakeSettingsRepository implements SettingsRepository {
  Result<SettingsOverview> overviewResult = const Success(fakeSettingsOverview);
  Result<void> setResult = const Success(null);
  Result<Set<SettingsDeleteBlocker>> blockersResult = const Success({});
  Result<void> deleteResult = const Success(null);
  Result<void> signOutResult = const Success(null);

  /// e.g. `messages off`, `delete`, `sign out`.
  final List<String> calls = [];

  @override
  Future<Result<SettingsOverview>> getOverview() async => overviewResult;

  @override
  Future<Result<void>> setNotification(
    SettingsNotificationChange change,
  ) async {
    calls.add('${change.group.value} ${change.enabled ? 'on' : 'off'}');
    return setResult;
  }

  @override
  Future<Result<Set<SettingsDeleteBlocker>>> getDeleteBlockers() async =>
      blockersResult;

  @override
  Future<Result<void>> deleteAccount() async {
    calls.add('delete');
    return deleteResult;
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('sign out');
    return signOutResult;
  }
}

/// For tests that open the settings routes: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeSettings(FakeSettingsRepository repository) {
  registerSettingsDependencies(getIt);
  getIt
    ..unregister<SettingsRepository>()
    ..registerSingleton<SettingsRepository>(repository);
}
