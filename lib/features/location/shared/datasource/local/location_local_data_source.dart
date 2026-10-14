import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';

/// Local data source for persisting user saved addresses.
abstract interface class LocationLocalDataSource {
  /// Loads all saved addresses from persistent storage.
  Future<List<LocationAddressModel>> getSavedAddresses();

  /// Persists a new address or updates an existing address in storage.
  Future<void> saveAddress(LocationAddressModel address);

  /// Removes an address by its [id] from storage.
  Future<void> deleteAddress(String id);
}

/// Implementation of [LocationLocalDataSource] using [SharedPreferences].
class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  /// Creates an instance of [LocationLocalDataSourceImpl].
  const LocationLocalDataSourceImpl(this._preferences);

  static const String _storageKey = 'watad_saved_addresses_v1';

  final SharedPreferences _preferences;

  @override
  Future<List<LocationAddressModel>> getSavedAddresses() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                LocationAddressModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveAddress(LocationAddressModel address) async {
    final list = await getSavedAddresses();
    final index = list.indexWhere((a) => a.id == address.id);
    final updatedList = List<LocationAddressModel>.from(list);
    if (index >= 0) {
      updatedList[index] = address;
    } else {
      updatedList.add(address);
    }
    await _persistList(updatedList);
  }

  @override
  Future<void> deleteAddress(String id) async {
    final list = await getSavedAddresses();
    final updatedList = list.where((a) => a.id != id).toList();
    await _persistList(updatedList);
  }

  Future<void> _persistList(List<LocationAddressModel> list) async {
    final encoded = jsonEncode(list.map((m) => m.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }
}
