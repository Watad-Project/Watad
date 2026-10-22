import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/features/users/admin/datasource/models/admin_user_model.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_filter.dart';
import 'package:watad/features/users/admin/domain/entities/admin_users_query.dart';

abstract interface class AdminUsersRemoteDataSource {
  Future<List<AdminUserModel>> getUsers(AdminUsersQuery query);

  Future<Map<AdminUsersFilter, int>> countUsers(String search);

  /// Throws PGRST116 (not found) when no user has [userId].
  Future<AdminUserModel> getUser(String userId);

  Future<void> setSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  });

  Future<void> setRole(String userId, UserRole role);
}

class AdminUsersRemoteDataSourceImpl implements AdminUsersRemoteDataSource {
  const AdminUsersRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, full_name, avatar_path, role, member_since, is_deleted, is_me, '
      'last_seen_at, is_online, is_business, company_name, specialized_field, '
      'business_city, verification_status, is_suspended, suspension_reason, '
      'suspended_at, suspended_by_name, client_project_count, '
      'contractor_project_count, listing_count, open_report_count';

  @override
  Future<List<AdminUserModel>> getUsers(AdminUsersQuery query) async {
    final request = _filtered(
      _client.from('v_admin_users').select(_columns),
      query.filter,
      query.search,
    );
    final rows = await request
        .order('member_since', ascending: false)
        .order('id', ascending: true)
        .range(query.offset, query.offset + query.limit - 1);
    return rows.map(_toModel).toList();
  }

  @override
  Future<Map<AdminUsersFilter, int>> countUsers(String search) async {
    final counts = await Future.wait([
      for (final filter in AdminUsersFilter.values)
        _filtered(
          _client.from('v_admin_users').select('id'),
          filter,
          search,
        ).count(CountOption.exact).then((response) => response.count),
    ]);
    return {
      for (final (index, filter) in AdminUsersFilter.values.indexed)
        filter: counts[index],
    };
  }

  @override
  Future<AdminUserModel> getUser(String userId) async {
    final row = await _client
        .from('v_admin_users')
        .select(_columns)
        .eq('id', userId)
        .single();
    return _toModel(row);
  }

  @override
  Future<void> setSuspension(
    String userId, {
    required bool suspended,
    String? reason,
  }) async {
    await _client.rpc<void>(
      'admin_set_user_suspension',
      params: {
        'p_user_id': userId,
        'p_suspended': suspended,
        'p_reason': reason,
      },
    );
  }

  @override
  Future<void> setRole(String userId, UserRole role) async {
    await _client.rpc<void>(
      'admin_set_user_role',
      params: {'p_user_id': userId, 'p_role': role.toJson()},
    );
  }

  /// [request] narrowed to [filter]'s users whose name, or company name,
  /// contains [search].
  PostgrestFilterBuilder<T> _filtered<T>(
    PostgrestFilterBuilder<T> request,
    AdminUsersFilter filter,
    String search,
  ) {
    var filtered = switch (filter) {
      AdminUsersFilter.all => request,
      AdminUsersFilter.clients =>
        request.eq('role', UserRole.user.toJson()).eq('is_business', false),
      AdminUsersFilter.businesses => request.eq('is_business', true),
      AdminUsersFilter.admins => request.eq('role', UserRole.admin.toJson()),
      AdminUsersFilter.suspended => request.eq('is_suspended', true),
    };
    final text = _searchText(search);
    if (text.isNotEmpty) {
      filtered = filtered.or(
        'full_name.ilike.*$text*,company_name.ilike.*$text*',
      );
    }
    return filtered;
  }

  /// The search, safe inside a PostgREST `or` filter: its separators and
  /// the `like` wildcards are dropped.
  static String _searchText(String search) =>
      search.trim().replaceAll(RegExp(r'[,()*%_\\"]'), ' ').trim();

  AdminUserModel _toModel(Map<String, dynamic> row) {
    final path = row['avatar_path'] as String?;
    return AdminUserModel.fromJson({
      ...row,
      // Avatars live in the public `avatars` bucket.
      'avatar_url': path == null || path.isEmpty
          ? null
          : _client.storage.from('avatars').getPublicUrl(path),
    });
  }
}
