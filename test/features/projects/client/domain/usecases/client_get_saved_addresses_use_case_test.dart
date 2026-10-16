import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_saved_addresses_use_case.dart';

class _FakeClientProjectsRepository implements ClientProjectsRepository {
  Result<List<ClientSavedAddress>> addressesResult = const Success([]);

  @override
  Future<Result<void>> createProject(ClientNewProject project) async =>
      const Success(null);

  @override
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses() async =>
      addressesResult;

  @override
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async => const Success(
    ClientSavedAddress(
      id: 'addr_1',
      name: 'Home',
      city: 'Riyadh',
      formattedAddress: 'Riyadh · An-Narjis',
    ),
  );
}

void main() {
  group('ClientGetSavedAddressesUseCase', () {
    test('calls repository getSavedAddresses', () async {
      final repo = _FakeClientProjectsRepository();
      repo.addressesResult = const Success([
        ClientSavedAddress(
          id: 'addr_1',
          name: 'Home',
          city: 'Riyadh',
          formattedAddress: 'Riyadh · An-Narjis',
        ),
      ]);

      final useCase = ClientGetSavedAddressesUseCase(repo);
      final result = await useCase();

      expect(result, isA<Success<List<ClientSavedAddress>>>());
      final addresses = (result as Success<List<ClientSavedAddress>>).data;
      expect(addresses.length, 1);
      expect(addresses.first.name, 'Home');
    });
  });
}
