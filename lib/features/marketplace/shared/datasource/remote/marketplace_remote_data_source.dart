import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_item_model.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_sort.dart';

abstract interface class MarketplaceRemoteDataSource {
  Future<List<MarketplaceItemModel>> getItems(MarketplaceQuery query);
  Future<List<MarketplaceItemModel>> getMyItems();
  Future<MarketplaceItemModel> getMyItem(String itemId);
  Future<MarketplaceItemModel> createItem(MarketplaceItemDraft draft);
  Future<MarketplaceItemModel> updateItem(
    String itemId,
    MarketplaceItemDraft draft,
  );
  Future<void> setItemActive(String itemId, {required bool isActive});
  Future<void> deleteItem(String itemId);
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

  @override
  Future<List<MarketplaceItemModel>> getMyItems() async {
    final rows = await _client
        .from('v_marketplace_items')
        .select(_columns)
        .eq('is_mine', true)
        .order('created_at', ascending: false)
        .order('id', ascending: true);
    return rows.map(_toModel).toList();
  }

  @override
  Future<MarketplaceItemModel> getMyItem(String itemId) async {
    final row = await _client
        .from('v_marketplace_items')
        .select(_columns)
        .eq('is_mine', true)
        .eq('id', itemId)
        .single();
    return _toModel(row);
  }

  @override
  Future<MarketplaceItemModel> createItem(MarketplaceItemDraft draft) async {
    final inserted = await _client
        .from('marketplace_items')
        .insert({
          'item_name': draft.name.trim(),
          'description': _cleanDescription(draft.description),
          'price': draft.price.toJson(),
          'stock_quantity': draft.stockQuantity,
          'is_active': draft.isActive,
          'category': draft.category.toJson(),
        })
        .select('id')
        .single();
    final itemId = inserted['id'] as String;
    if (draft.photos.isNotEmpty) {
      final paths = await _resolvePhotos(itemId, draft.photos);
      await _client.rpc<void>(
        'set_marketplace_item_photos',
        params: {'p_item_id': itemId, 'p_paths': paths},
      );
    }
    return getMyItem(itemId);
  }

  @override
  Future<MarketplaceItemModel> updateItem(
    String itemId,
    MarketplaceItemDraft draft,
  ) async {
    await _client
        .from('marketplace_items')
        .update({
          'item_name': draft.name.trim(),
          'description': _cleanDescription(draft.description),
          'price': draft.price.toJson(),
          'stock_quantity': draft.stockQuantity,
          'category': draft.category.toJson(),
        })
        .eq('id', itemId);
    final paths = await _resolvePhotos(itemId, draft.photos);
    await _client.rpc<void>(
      'set_marketplace_item_photos',
      params: {'p_item_id': itemId, 'p_paths': paths},
    );
    return getMyItem(itemId);
  }

  @override
  Future<void> setItemActive(String itemId, {required bool isActive}) async {
    await _client
        .from('marketplace_items')
        .update({'is_active': isActive})
        .eq('id', itemId);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _client
        .from('marketplace_items')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', itemId);
  }

  Future<List<String>> _resolvePhotos(
    String itemId,
    List<String> photos,
  ) async {
    final userId = _client.auth.currentUser?.id ?? '';
    final prefix = '$userId/marketplace/$itemId/';
    final resolved = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo.startsWith(prefix)) {
        resolved.add(photo);
      } else {
        resolved.add(await _uploadPhoto(userId, itemId, i, photo));
      }
    }
    return resolved;
  }

  Future<String> _uploadPhoto(
    String userId,
    String itemId,
    int index,
    String filePath,
  ) async {
    final file = File(filePath);
    final ext = _extension(filePath);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final storagePath = '$userId/marketplace/$itemId/${stamp}_$index.$ext';
    await _client.storage
        .from('images')
        .upload(
          storagePath,
          file,
          fileOptions: FileOptions(contentType: _contentType(ext)),
        );
    return storagePath;
  }

  static String _extension(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'webp' => ext,
      _ => 'jpg',
    };
  }

  static String _contentType(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  static String? _cleanDescription(String? description) {
    final trimmed = description?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
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
