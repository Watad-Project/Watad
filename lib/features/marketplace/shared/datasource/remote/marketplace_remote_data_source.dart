import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_item_model.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';

abstract interface class MarketplaceRemoteDataSource {
  Future<List<MarketplaceItemModel>> getItems(MarketplaceQuery query);
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, item_name, description, price, stock_quantity, in_stock, is_active, '
      'created_at, updated_at, seller_id, seller_name, seller_avatar_path, '
      'seller_is_verified_business, seller_rating_avg, seller_rating_count, '
      'is_mine, removed_at, removal_reason, category, photo_paths';

  @override
  Future<List<MarketplaceItemModel>> getItems(MarketplaceQuery query) async {
    var filtered = _client
        .from('v_marketplace_items')
        .select(_columns)
        .eq('is_active', true);

    if (query.category case final category?) {
      filtered = filtered.eq('category', category.toJson());
    }

    final text = _searchText(query.search);
    if (text.isNotEmpty) {
      filtered = filtered.ilike('item_name', '%$text%');
    }

    final ordered = switch (query.sort) {
      MarketplaceSort.newest =>
        filtered
            .order('created_at', ascending: false)
            .order('id', ascending: true),
      MarketplaceSort.priceLowToHigh =>
        filtered
            .order('price', ascending: true)
            .order('created_at', ascending: false)
            .order('id', ascending: true),
      MarketplaceSort.priceHighToLow =>
        filtered
            .order('price', ascending: false)
            .order('created_at', ascending: false)
            .order('id', ascending: true),
    };

    final rows = await ordered.range(
      query.offset,
      query.offset + query.limit - 1,
    );
    return rows.map(_toModel).toList();
  }

  /// Drops PostgREST and LIKE wildcards from [search].
  static String _searchText(String search) =>
      search.trim().replaceAll(RegExp(r'[,()*%_\\"]'), ' ').trim();

  MarketplaceItemModel _toModel(Map<String, dynamic> row) {
    final avatarPath = row['seller_avatar_path'] as String?;
    final rawPhotos = row['photo_paths'] as List<dynamic>?;
    final photoPaths = rawPhotos == null
        ? const <String>[]
        : rawPhotos.whereType<String>().where((p) => p.isNotEmpty).toList();

    return MarketplaceItemModel.fromJson({
      ...row,
      'seller_avatar_url': avatarPath == null || avatarPath.isEmpty
          ? null
          : _client.storage.from('avatars').getPublicUrl(avatarPath),
      'photo_urls': [
        for (final path in photoPaths)
          _client.storage.from('images').getPublicUrl(path),
      ],
    });
  }
}
