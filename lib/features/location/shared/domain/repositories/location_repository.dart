import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';

/// Repository interface for managing user saved addresses and location data.
abstract interface class LocationRepository {
  /// Retrieves the list of saved addresses for the current user.
  Future<Result<List<LocationAddress>>> getSavedAddresses();

  /// Saves a new address or updates an existing address in the user's saved list.
  Future<Result<LocationAddress>> saveAddress(LocationAddress address);

  /// Deletes a saved address by its [id].
  Future<Result<void>> deleteAddress(String id);

  /// Resolves the address of the given map pin coordinates [lat] and [lng] using the geocode Edge Function (GRA-19).
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  });

  /// Reverse geocodes the given map pin coordinates [lat] and [lng] using the geocode Edge Function.
  Future<Result<LocationAddress>> geocodeCoordinates({
    required double lat,
    required double lng,
  });
}
