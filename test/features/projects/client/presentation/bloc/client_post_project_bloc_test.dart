import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_address_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_saved_addresses_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

void main() {
  group('ClientPostProjectBloc', () {
    test('initial state defaults to step 1 and no selected type', () {
      final bloc = ClientPostProjectBloc();
      expect(bloc.state.currentStep, 1);
      expect(bloc.state.projectType, isNull);
      expect(bloc.state.status, ClientPostProjectStatus.initial);
      expect(bloc.state.canProceedFromDetails, isFalse);
      bloc.close();
    });

    test('selects newHouse type with deed required and 3 steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.projectType == ClientProjectType.newHouse &&
                s.requiresDeed == true &&
                s.totalSteps == 3;
          }),
        ),
      );

      await bloc.close();
    });

    test('selects repairs type without deed and 2 steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.repairs));
      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.projectType == ClientProjectType.repairs &&
                s.requiresDeed == false &&
                s.totalSteps == 2;
          }),
        ),
      );

      await bloc.close();
    });

    test('handles step 2 fields and validation', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      bloc.add(const ClientPostProjectScopeChanged('House foundation work'));
      bloc.add(ClientPostProjectMinBudgetChanged(Money.fromSar(50000)));
      bloc.add(ClientPostProjectMaxBudgetChanged(Money.fromSar(100000)));
      bloc.add(const ClientPostProjectLocationChanged('Riyadh Al-Morouj'));
      bloc.add(const ClientPostProjectPhotoAdded('photo1.jpg'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.scopeOfWork == 'House foundation work' &&
                s.minBudget == Money.fromSar(50000) &&
                s.maxBudget == Money.fromSar(100000) &&
                s.locationAddress == 'Riyadh Al-Morouj' &&
                s.photos.length == 1 &&
                s.canProceedFromDetails == true &&
                s.isBudgetValid == true;
          }),
        ),
      );

      bloc.add(const ClientPostProjectPhotoRemoved(0));
      await expectLater(
        bloc.stream,
        emits(predicate<ClientPostProjectState>((s) => s.photos.isEmpty)),
      );

      await bloc.close();
    });

    test('invalidates budget when max is less than min', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(ClientPostProjectMinBudgetChanged(Money.fromSar(100000)));
      bloc.add(ClientPostProjectMaxBudgetChanged(Money.fromSar(50000)));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.isBudgetValid == false && s.canProceedFromDetails == false;
          }),
        ),
      );

      await bloc.close();
    });

    test('advances and retreats between steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(
        const ClientPostProjectTypeSelected(ClientProjectType.renovation),
      );
      bloc.add(const ClientPostProjectStepAdvanced());
      bloc.add(const ClientPostProjectStepRetreated());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ClientPostProjectState>((s) => s.currentStep == 1),
          predicate<ClientPostProjectState>((s) => s.currentStep == 2),
          predicate<ClientPostProjectState>((s) => s.currentStep == 1),
        ]),
      );

      await bloc.close();
    });

    test('handles step 3 deed upload and review lifecycle', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      expect(bloc.state.deedStatus, ClientDeedVerificationStatus.none);
      expect(bloc.state.canProceedFromDeed, isFalse);

      bloc.add(
        const ClientPostProjectDeedSelected(
          filePath: 'path/to/deed.pdf',
          fileName: 'my_deed.pdf',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.deedFilePath == 'path/to/deed.pdf' &&
                s.deedFileName == 'my_deed.pdf' &&
                s.deedStatus == ClientDeedVerificationStatus.none &&
                s.canProceedFromDeed == true;
          }),
        ),
      );

      bloc.add(
        const ClientPostProjectDeedStatusChanged(
          ClientDeedVerificationStatus.underReview,
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedStatus == ClientDeedVerificationStatus.underReview;
          }),
        ),
      );

      bloc.add(
        const ClientPostProjectDeedStatusChanged(
          ClientDeedVerificationStatus.verified,
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedStatus == ClientDeedVerificationStatus.verified &&
                s.canProceedFromDeed == true;
          }),
        ),
      );

      bloc.add(
        const ClientPostProjectDeedStatusChanged(
          ClientDeedVerificationStatus.rejected,
          rejectionReason: 'مرفوض — اسم المالك لا يطابق الهوية',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedStatus == ClientDeedVerificationStatus.rejected &&
                s.deedRejectionReason == 'مرفوض — اسم المالك لا يطابق الهوية';
          }),
        ),
      );

      bloc.add(const ClientPostProjectDeedRetry());

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedFilePath == null &&
                s.deedFileName == null &&
                s.deedStatus == ClientDeedVerificationStatus.none &&
                s.deedRejectionReason == null &&
                s.canProceedFromDeed == false;
          }),
        ),
      );

      await bloc.close();
    });

    test('handles project submission on review step', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.repairs));
      bloc.add(const ClientPostProjectScopeChanged('Repair pipe'));
      bloc.add(ClientPostProjectMinBudgetChanged(Money.fromSar(500)));
      bloc.add(ClientPostProjectMaxBudgetChanged(Money.fromSar(1500)));
      bloc.add(const ClientPostProjectLocationChanged('Riyadh'));
      bloc.add(const ClientPostProjectStepAdvanced()); // step 2 (review)

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.currentStep == 2 &&
                s.isReviewStep == true &&
                s.canPublish == true;
          }),
        ),
      );

      bloc.add(const ClientPostProjectSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ClientPostProjectState>(
            (s) => s.status == ClientPostProjectStatus.submitting,
          ),
          predicate<ClientPostProjectState>(
            (s) => s.status == ClientPostProjectStatus.success,
          ),
        ]),
      );

      await bloc.close();
    });

    test(
      'calls createProjectUseCase and emits success on Success result',
      () async {
        final repo = _FakeClientProjectsRepository();
        repo.result = const Success(null);
        final useCase = ClientCreateProjectUseCase(repo);
        final bloc = ClientPostProjectBloc(createProjectUseCase: useCase);

        bloc.add(
          const ClientPostProjectTypeSelected(ClientProjectType.repairs),
        );
        bloc.add(const ClientPostProjectScopeChanged('Fix kitchen sink'));
        bloc.add(ClientPostProjectMinBudgetChanged(Money.fromSar(500)));
        bloc.add(ClientPostProjectMaxBudgetChanged(Money.fromSar(1500)));
        bloc.add(const ClientPostProjectLocationChanged('Riyadh · An-Narjis'));
        bloc.add(const ClientPostProjectSubmitted());

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<ClientPostProjectState>(
              (s) => s.status == ClientPostProjectStatus.success,
            ),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'calls createProjectUseCase and emits failure on Failed result',
      () async {
        final repo = _FakeClientProjectsRepository();
        repo.result = const Failed(ServerFailure('Database error'));
        final useCase = ClientCreateProjectUseCase(repo);
        final bloc = ClientPostProjectBloc(createProjectUseCase: useCase);

        bloc.add(
          const ClientPostProjectTypeSelected(ClientProjectType.repairs),
        );
        bloc.add(const ClientPostProjectScopeChanged('Fix kitchen sink'));
        bloc.add(ClientPostProjectMinBudgetChanged(Money.fromSar(500)));
        bloc.add(ClientPostProjectMaxBudgetChanged(Money.fromSar(1500)));
        bloc.add(const ClientPostProjectLocationChanged('Riyadh · An-Narjis'));
        bloc.add(const ClientPostProjectSubmitted());

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<ClientPostProjectState>(
              (s) =>
                  s.status == ClientPostProjectStatus.failure &&
                  s.failure is ServerFailure,
            ),
          ),
        );

        await bloc.close();
      },
    );

    test('loads saved addresses on init and selects the first one', () async {
      final repo = _FakeClientProjectsRepository();
      const testAddr = ClientSavedAddress(
        id: 'addr_1',
        name: 'Home',
        city: 'Riyadh',
        district: 'An-Narjis',
        street: 'Anas Ibn Malik',
        buildingNumber: '4210',
        postalCode: '13324',
        formattedAddress: 'Riyadh · An-Narjis',
      );
      repo.addressesResult = const Success([testAddr]);
      final getAddressesUseCase = ClientGetSavedAddressesUseCase(repo);
      final bloc = ClientPostProjectBloc(
        getSavedAddressesUseCase: getAddressesUseCase,
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>(
            (s) =>
                s.savedAddresses.length == 1 &&
                s.selectedAddress?.id == 'addr_1' &&
                s.addressId == 'addr_1',
          ),
        ),
      );

      await bloc.close();
    });

    test(
      'a new address saved on the map is reloaded and selected (GRA-34)',
      () async {
        final repo = _FakeClientProjectsRepository();
        const home = ClientSavedAddress(
          id: 'addr_1',
          name: 'Home',
          city: 'Riyadh',
          district: 'An-Narjis',
          street: 'Anas Ibn Malik',
          buildingNumber: '4210',
          postalCode: '13324',
          formattedAddress: 'Riyadh · An-Narjis',
        );
        const site = ClientSavedAddress(
          id: 'addr_2',
          name: 'Site',
          city: 'Madinah',
          district: 'Al-Aziziyah',
          street: 'King Abdullah Rd',
          buildingNumber: '7310',
          postalCode: '42311',
          formattedAddress: 'Madinah · Al-Aziziyah',
        );
        repo.addressesResult = const Success([home]);
        final bloc = ClientPostProjectBloc(
          getSavedAddressesUseCase: ClientGetSavedAddressesUseCase(repo),
        );
        await bloc.stream.firstWhere((s) => s.selectedAddress?.id == 'addr_1');

        // The map picker saved addr_2 and returned its id.
        repo.addressesResult = const Success([site, home]);
        bloc.add(const ClientPostProjectAddressesRequested(selectId: 'addr_2'));

        final state = await bloc.stream.firstWhere(
          (s) => !s.isLoadingAddresses && s.savedAddresses.length == 2,
        );
        expect(state.selectedAddress?.id, 'addr_2');
        expect(state.addressId, 'addr_2');
        expect(state.locationAddress, 'Madinah · Al-Aziziyah');
        expect(state.locationCity, 'Madinah');

        await bloc.close();
      },
    );

    test('creates address and adds it to savedAddresses', () async {
      final repo = _FakeClientProjectsRepository();
      const newAddr = ClientSavedAddress(
        id: 'addr_2',
        name: 'Office',
        city: 'Jeddah',
        district: 'Al-Rawdah',
        street: 'Prince Sultan',
        buildingNumber: '1122',
        postalCode: '23432',
        formattedAddress: 'Jeddah · Al-Rawdah',
      );
      repo.createAddressResult = const Success(newAddr);
      final createAddressUseCase = ClientCreateAddressUseCase(repo);
      final bloc = ClientPostProjectBloc(
        createAddressUseCase: createAddressUseCase,
      );

      bloc.add(
        const ClientPostProjectAddressCreated(
          name: 'Office',
          city: 'Jeddah',
          district: 'Al-Rawdah',
          street: 'Prince Sultan',
          buildingNumber: '1122',
          postalCode: '23432',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>(
            (s) =>
                s.selectedAddress?.id == 'addr_2' &&
                s.locationCity == 'Jeddah' &&
                s.locationDistrict == 'Al-Rawdah',
          ),
        ),
      );

      await bloc.close();
    });

    test('resets back to initial state', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      bloc.add(const ClientPostProjectReset());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ClientPostProjectState>(
            (s) => s.projectType == ClientProjectType.newHouse,
          ),
          predicate<ClientPostProjectState>(
            (s) => s.projectType == null && s.currentStep == 1,
          ),
        ]),
      );

      await bloc.close();
    });
  });
}

class _FakeClientProjectsRepository implements ClientProjectsRepository {
  Result<void> result = const Success(null);
  Result<List<ClientSavedAddress>> addressesResult = const Success([]);
  Result<ClientSavedAddress> createAddressResult = const Success(
    ClientSavedAddress(
      id: 'addr_1',
      name: 'Home',
      city: 'Riyadh',
      district: 'An-Narjis',
      street: 'Anas Ibn Malik',
      buildingNumber: '4210',
      postalCode: '13324',
      formattedAddress: 'Riyadh · An-Narjis',
    ),
  );

  @override
  Future<Result<void>> createProject(ClientNewProject project) async => result;

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
  }) async => createAddressResult;
}
