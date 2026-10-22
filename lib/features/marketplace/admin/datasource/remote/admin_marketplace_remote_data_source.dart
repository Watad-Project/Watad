import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/marketplace/admin/datasource/models/admin_marketplace_item_model.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_filter.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';

abstract interface class AdminMarketplaceRemoteDataSource {
  Future<List<AdminMarketplaceItemModel>> getItems(AdminMarketplaceQuery query);

  Future<Map<AdminMarketplaceFilter, int>> countItems(String search);

  /// Throws PGRST116 (not found) when no listing has [itemId].
  Future<AdminMarketplaceItemModel> getItem(String itemId);

  Future<void> removeItem(String itemId, String reason);
}

class AdminMarketplaceRemoteDataSourceImpl
    implements AdminMarketplaceRemoteDataSource {
  const AdminMarketplaceRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, item_name, description, price, stock_quantity, status, '
      'created_at, updated_at, seller_id, seller_name, seller_avatar_path, '
      'seller_is_verified_business, seller_rating_avg, seller_rating_count, '
      'removed_at, removal_reason, removed_by_name, order_count, '
      'open_report_count';

  @override
  Future<List<AdminMarketplaceItemModel>> getItems(
    AdminMarketplaceQuery query,
  ) async {
    final rows =
        await _filtered(
              _client.from('v_admin_marketplace_items').select(_columns),
              query.filter,
              query.search,
            )
            .order('created_at', ascending: false)
            .order('id', ascending: true)
            .range(query.offset, query.offset + query.limit - 1);
    return rows.map(_toModel).toList();
  }

  @override
  Future<Map<AdminMarketplaceFilter, int>> countItems(String search) async {
    final counts = await Future.wait([
      for (final filter in AdminMarketplaceFilter.values)
        _filtered(
          _client.from('v_admin_marketplace_items').select('id'),
          filter,
          search,
        ).count(CountOption.exact).then((response) => response.count),
    ]);
    return {
      for (final (index, filter) in AdminMarketplaceFilter.values.indexed)
        filter: counts[index],
    };
  }

  @override
  Future<AdminMarketplaceItemModel> getItem(String itemId) async {
    final row = await _client
        .from('v_admin_marketplace_items')
        .select(_columns)
        .eq('id', itemId)
        .single();
    return _toModel(row);
  }

  @override
  Future<void> removeItem(String itemId, String reason) async {
    await _client.rpc<void>(
      'admin_remove_listing',
      params: {'p_item_id': itemId, 'p_reason': reason},
    );
  }

  /// [request] narrowed to [filter]'s listings whose item or seller name
  /// contains [search].
  PostgrestFilterBuilder<T> _filtered<T>(
    PostgrestFilterBuilder<T> request,
    AdminMarketplaceFilter filter,
    String search,
  ) {
    var filtered = switch (filter.status) {
      final status? => request.eq(
        'status',
        AdminMarketplaceItemModel.valueOf(status),
      ),
      null => request,
    };
    final text = _searchText(search);
    if (text.isNotEmpty) {
      filtered = filtered.or(
        'item_name.ilike.*$text*,seller_name.ilike.*$text*',
      );
    }
    return filtered;
  }

  /// The search, safe inside a PostgREST `or` filter: its separators and
  /// the `like` wildcards are dropped.
  static String _searchText(String search) =>
      search.trim().replaceAll(RegExp(r'[,()*%_\\"]'), ' ').trim();

  AdminMarketplaceItemModel _toModel(Map<String, dynamic> row) {
    final path = row['seller_avatar_path'] as String?;
    return AdminMarketplaceItemModel.fromJson({
      ...row,
      // Avatars live in the public `avatars` bucket.
      'seller_avatar_url': path == null || path.isEmpty
          ? null
          : _client.storage.from('avatars').getPublicUrl(path),
    });
  }
}
