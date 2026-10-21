import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_place.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Where a suggested place is, from its Google place id.
class GetPlaceUseCase implements UseCase<LocationPlace, String> {
  const GetPlaceUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Result<LocationPlace>> call(String placeId) =>
      _repository.getPlace(placeId);
}
