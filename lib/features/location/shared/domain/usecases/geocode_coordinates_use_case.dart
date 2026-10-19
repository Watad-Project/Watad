import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Parameters for [GeocodeCoordinatesUseCase].
class GeocodeCoordinatesParams {
  const GeocodeCoordinatesParams({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// Calls the geocode Edge Function via [LocationRepository] to resolve
/// address fields from map coordinates (GRA-19).
class GeocodeCoordinatesUseCase
    implements UseCase<LocationAddress, GeocodeCoordinatesParams> {
  const GeocodeCoordinatesUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Result<LocationAddress>> call(GeocodeCoordinatesParams params) =>
      _repository.geocodeCoordinates(
        lat: params.latitude,
        lng: params.longitude,
      );
}
