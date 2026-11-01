import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/settings/shared/datasource/models/settings_overview_model.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_notification_change.dart';

abstract interface class SettingsRemoteDataSource {
  Future<SettingsOverviewModel> getOverview();

  Future<void> setNotification(SettingsNotificationChange change);

  Future<Set<SettingsDeleteBlocker>> getDeleteBlockers();

  Future<void> deleteAccount();

  Future<void> signOut();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<SettingsOverviewModel> getOverview() async {
    final profile = await _client
        .from('v_my_profile')
        .select('is_business')
        .single();
    final isBusiness = profile['is_business'] as bool? ?? false;
    final bankDetails = isBusiness
        ? await _client
              .from('v_contractor_bank_details')
              .select('contractor_id')
              .eq('is_mine', true)
              .maybeSingle()
        : null;
    final notifications = await _client
        .from('v_my_notification_preferences')
        .select('notification_group, push_enabled');
    return SettingsOverviewModel.fromJson({
      'is_business': isBusiness,
      'has_bank_details': bankDetails != null,
      'notifications': notifications,
    });
  }

  @override
  Future<void> setNotification(SettingsNotificationChange change) async {
    await _client.rpc<void>(
      'set_notification_preference',
      params: {'p_group': change.group.toJson(), 'p_enabled': change.enabled},
    );
  }

  @override
  Future<Set<SettingsDeleteBlocker>> getDeleteBlockers() async {
    // The checks of private.close_account(), through my own views.
    final orders = await _client
        .from('v_my_orders')
        .select('id')
        .inFilter('status', ['paid', 'shipped'])
        .limit(1);
    final projects = await _client
        .from('v_my_projects')
        .select('id')
        .eq('status', 'in_progress')
        .limit(1);
    return {
      if (orders.isNotEmpty) SettingsDeleteBlocker.activeOrders,
      if (projects.isNotEmpty) SettingsDeleteBlocker.activeProjects,
    };
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_my_account');
  }

  @override
  Future<void> signOut() async {
    // Offline first, while the session still exists. Best effort: a
    // suspended account can't save presence, and its presence ends by
    // itself within two minutes, so this never stops the sign-out.
    await _client
        .rpc<void>('set_my_presence', params: {'p_online': false})
        .then<void>((_) {}, onError: (Object _) {});
    await _client.auth.signOut();
  }
}
