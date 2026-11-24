import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/domain/repositories/location_repository.dart';

/// Deletes one of my saved addresses. The site of a project that is still
/// going is refused here: deleting it would clear the project's address,
/// and the contractor would lose the site.
class DeleteAddressUseCase implements UseCase<void, LocationAddress> {
  const DeleteAddressUseCase(this._repository);

  final LocationRepository _repository;

  @override
  Future<Result<void>> call(LocationAddress address) {
    if (address.isActiveProjectSite) {
      return Future.value(
        const Failed(
          ValidationFailure('location.addresses_error_project_site'),
        ),
      );
    }
    return _repository.deleteAddress(address.id);
  }
}
