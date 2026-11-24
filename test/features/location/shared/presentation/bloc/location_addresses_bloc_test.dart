import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/location/shared/domain/usecases/delete_address_use_case.dart';
import 'package:watad/features/location/shared/domain/usecases/get_saved_addresses_use_case.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_addresses_bloc.dart';

import '../../../../../helpers/fake_location_repository.dart';

LocationAddressesBloc _bloc(FakeLocationRepository repository) =>
    LocationAddressesBloc(
      GetSavedAddressesUseCase(repository),
      DeleteAddressUseCase(repository),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads my addresses', () async {
    final bloc = _bloc(FakeLocationRepository())
      ..add(const LocationAddressesFetched());
    await _settle();

    expect(bloc.state.status, LocationAddressesStatus.success);
    expect(bloc.state.addresses, hasLength(2));
    await bloc.close();
  });

  test('a failed load keeps the failure', () async {
    final repository = FakeLocationRepository()
      ..addressesResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const LocationAddressesFetched());
    await _settle();

    expect(bloc.state.status, LocationAddressesStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('a delete removes it and reloads', () async {
    final repository = FakeLocationRepository();
    final bloc = _bloc(repository)..add(const LocationAddressesFetched());
    await _settle();

    bloc.add(LocationAddressDeleted(fakeSavedAddresses.first));
    await _settle();

    expect(repository.deleted, ['a-home']);
    expect(bloc.state.deleted, isTrue);
    expect(bloc.state.addresses!.map((a) => a.id), ['a-site']);
    await bloc.close();
  });

  test('the site of a going project is never sent to delete', () async {
    final repository = FakeLocationRepository();
    final bloc = _bloc(repository)..add(const LocationAddressesFetched());
    await _settle();

    bloc.add(LocationAddressDeleted(fakeSavedAddresses.last));
    await _settle();

    expect(repository.deleted, isEmpty);
    expect(
      bloc.state.actionFailure?.messageKey,
      'location.addresses_error_project_site',
    );
    await bloc.close();
  });
}
