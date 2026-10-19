import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Retrieves the list of saved addresses for the user.
final class GetSavedAddressesUseCase
    implements UseCase<List<LocationAddress>, NoParams> {
  /// Creates an instance of [GetSavedAddressesUseCase].
  const GetSavedAddressesUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Result<List<LocationAddress>>> call(NoParams params) {
    return _repository.getSavedAddresses();
  }
}
