import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';
import 'package:watad/features/location/shared/datasource/remote/location_remote_data_source.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Concrete implementation of [LocationRepository] utilizing [LocationRemoteDataSource].
class LocationRepositoryImpl implements LocationRepository {
  /// Creates an instance of [LocationRepositoryImpl].
  const LocationRepositoryImpl(this._remoteDataSource);

  final LocationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() =>
      guardSupabaseCall(() async {
        final models = await _remoteDataSource.getSavedAddresses();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<LocationAddress>> saveAddress(LocationAddress address) =>
      guardSupabaseCall(() async {
        final model = LocationAddressModel.fromEntity(address);
        final saved = await _remoteDataSource.saveAddress(model);
        return saved.toEntity();
      });

  @override
  Future<Result<void>> deleteAddress(String id) =>
      guardSupabaseCall(() => _remoteDataSource.deleteAddress(id));

  @override
  Future<Result<LocationAddress>> addressAt({
    required double lat,
    required double lng,
  }) => guardSupabaseCall(() async {
    final model = await _remoteDataSource.addressAt(lat: lat, lng: lng);
    return model.toEntity();
  });

  @override
  Future<Result<LocationAddress>> geocodeCoordinates({
    required double lat,
    required double lng,
  }) => guardSupabaseCall(() async {
    final model = await _remoteDataSource.addressAt(lat: lat, lng: lng);
    return model.toEntity();
  });
}
