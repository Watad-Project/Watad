import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/settings/shared/datasource/remote/settings_remote_data_source.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<Result<SettingsOverview>> getOverview() =>
      guardSupabaseCall(_remote.getOverview);

  @override
  Future<Result<void>> setNotification(SettingsNotificationChange change) =>
      guardSupabaseCall(() => _remote.setNotification(change));

  @override
  Future<Result<Set<SettingsDeleteBlocker>>> getDeleteBlockers() =>
      guardSupabaseCall(_remote.getDeleteBlockers);

  @override
  Future<Result<void>> deleteAccount() =>
      guardSupabaseCall(_remote.deleteAccount);

  @override
  Future<Result<void>> signOut() => guardSupabaseCall(_remote.signOut);
}
