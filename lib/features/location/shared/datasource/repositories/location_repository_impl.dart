import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/location/shared/datasource/local/location_local_data_source.dart';
import 'package:watad/features/location/shared/datasource/models/location_address_model.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Concrete implementation of [LocationRepository] utilizing [LocationLocalDataSource].
class LocationRepositoryImpl implements LocationRepository {
  /// Creates an instance of [LocationRepositoryImpl].
  const LocationRepositoryImpl(this._localDataSource);

  final LocationLocalDataSource _localDataSource;

  @override
  Future<Result<List<LocationAddress>>> getSavedAddresses() =>
      guardSupabaseCall(() async {
        final models = await _localDataSource.getSavedAddresses();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<void>> saveAddress(LocationAddress address) =>
      guardSupabaseCall(() async {
        final model = LocationAddressModel.fromEntity(address);
        await _localDataSource.saveAddress(model);
      });

  @override
  Future<Result<void>> deleteAddress(String id) =>
      guardSupabaseCall(() => _localDataSource.deleteAddress(id));
}
