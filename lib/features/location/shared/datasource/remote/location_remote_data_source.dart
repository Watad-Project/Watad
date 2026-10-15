import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';

/// Remote data source for user saved addresses in Supabase.
abstract interface class LocationRemoteDataSource {
  /// Reads all saved addresses for the authenticated user from view `v_my_addresses`.
  Future<List<LocationAddressModel>> getSavedAddresses();

  /// Inserts or updates an address row in `addresses` table.
  /// Allowed columns: `name`, `city`, `district`, `street`, `building_number`, `postal_code`.
  Future<LocationAddressModel> saveAddress(LocationAddressModel address);

  /// Deletes an address from `addresses` table by its [id].
  Future<void> deleteAddress(String id);
}

/// Implementation of [LocationRemoteDataSource] using [SupabaseClient].
class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  const LocationRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LocationAddressModel>> getSavedAddresses() async {
    final response = await _client.from('v_my_addresses').select();
    final rows = response as List<dynamic>;
    return rows
        .map(
          (row) => LocationAddressModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<LocationAddressModel> saveAddress(LocationAddressModel address) async {
    final effectiveName = address.name.trim().isNotEmpty
        ? address.name.trim()
        : (address.district.trim().isNotEmpty
              ? address.district.trim()
              : address.city.trim());

    if (address.id.isNotEmpty && !address.id.startsWith('addr_')) {
      final response = await _client
          .from('addresses')
          .update({
            'name': effectiveName,
            'city': address.city.trim(),
            'district': address.district.trim(),
            'street': address.street.trim(),
            'building_number': address.buildingNumber.trim(),
            'postal_code': address.postalCode.trim(),
          })
          .eq('id', address.id)
          .select()
          .single();
      return LocationAddressModel.fromJson(response);
    } else {
      final response = await _client
          .from('addresses')
          .insert({
            'name': effectiveName,
            'city': address.city.trim(),
            'district': address.district.trim(),
            'street': address.street.trim(),
            'building_number': address.buildingNumber.trim(),
            'postal_code': address.postalCode.trim(),
          })
          .select()
          .single();
      return LocationAddressModel.fromJson(response);
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _client.from('addresses').delete().eq('id', id);
  }
}
