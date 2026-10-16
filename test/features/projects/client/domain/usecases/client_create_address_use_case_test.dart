import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_address_use_case.dart';

class _FakeClientProjectsRepository implements ClientProjectsRepository {
  ClientSavedAddress createdAddress = const ClientSavedAddress(
    id: 'addr_new',
    name: 'Office',
    city: 'Jeddah',
    district: 'Al-Rawdah',
    street: 'Prince Sultan',
    buildingNumber: '1234',
    postalCode: '12345',
    formattedAddress: 'Jeddah · Al-Rawdah',
  );

  @override
  Future<Result<void>> createProject(ClientNewProject project) async =>
      const Success(null);

  @override
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async => Success(createdAddress);
}

void main() {
  group('ClientCreateAddressUseCase', () {
    test('calls repository createAddress with parameters', () async {
      final repo = _FakeClientProjectsRepository();
      final useCase = ClientCreateAddressUseCase(repo);

      final result = await useCase(
        const ClientCreateAddressParams(
          name: 'Office',
          city: 'Jeddah',
          district: 'Al-Rawdah',
          street: 'Prince Sultan',
          buildingNumber: '1234',
          postalCode: '12345',
        ),
      );

      expect(result, isA<Success<ClientSavedAddress>>());
      final address = (result as Success<ClientSavedAddress>).data;
      expect(address.id, 'addr_new');
      expect(address.name, 'Office');
    });
  });
}
