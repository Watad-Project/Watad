import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Saves an address to the user's saved addresses list.
final class SaveAddressUseCase
    implements UseCase<LocationAddress, LocationAddress> {
  /// Creates an instance of [SaveAddressUseCase].
  const SaveAddressUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Result<LocationAddress>> call(LocationAddress params) {
    return _repository.saveAddress(params);
  }
}
