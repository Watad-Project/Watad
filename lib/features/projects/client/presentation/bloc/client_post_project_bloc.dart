import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_address_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_saved_addresses_use_case.dart';

part 'client_post_project_event.dart';
part 'client_post_project_state.dart';

class ClientPostProjectBloc
    extends Bloc<ClientPostProjectEvent, ClientPostProjectState> {
  ClientPostProjectBloc({
    this.createProjectUseCase,
    this.getSavedAddressesUseCase,
    this.createAddressUseCase,
  }) : super(const ClientPostProjectState()) {
    on<ClientPostProjectTypeSelected>(_onTypeSelected);
    on<ClientPostProjectScopeChanged>(_onScopeChanged);
    on<ClientPostProjectMinBudgetChanged>(_onMinBudgetChanged);
    on<ClientPostProjectMaxBudgetChanged>(_onMaxBudgetChanged);
    on<ClientPostProjectAddressesRequested>(_onAddressesRequested);
    on<ClientPostProjectAddressSelected>(_onAddressSelected);
    on<ClientPostProjectAddressCreated>(_onAddressCreated);
    on<ClientPostProjectLocationChanged>(_onLocationChanged);
    on<ClientPostProjectPhotoAdded>(_onPhotoAdded);
    on<ClientPostProjectPhotoRemoved>(_onPhotoRemoved);
    on<ClientPostProjectDeedSelected>(_onDeedSelected);
    on<ClientPostProjectDeedStatusChanged>(_onDeedStatusChanged);
    on<ClientPostProjectDeedRetry>(_onDeedRetry);
    on<ClientPostProjectStepAdvanced>(_onStepAdvanced);
    on<ClientPostProjectStepRetreated>(_onStepRetreated);
    on<ClientPostProjectReset>(_onReset);
    on<ClientPostProjectSubmitted>(_onSubmitted);

    // Initial load of addresses from Supabase v_my_addresses
    add(const ClientPostProjectAddressesRequested());
  }

  final ClientCreateProjectUseCase? createProjectUseCase;
  final ClientGetSavedAddressesUseCase? getSavedAddressesUseCase;
  final ClientCreateAddressUseCase? createAddressUseCase;

  void _onTypeSelected(
    ClientPostProjectTypeSelected event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(projectType: event.type));
  }

  void _onScopeChanged(
    ClientPostProjectScopeChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(scopeOfWork: event.scope));
  }

  void _onMinBudgetChanged(
    ClientPostProjectMinBudgetChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(minBudget: event.minBudget));
  }

  void _onMaxBudgetChanged(
    ClientPostProjectMaxBudgetChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(state.copyWith(maxBudget: event.maxBudget));
  }

  Future<void> _onAddressesRequested(
    ClientPostProjectAddressesRequested event,
    Emitter<ClientPostProjectState> emit,
  ) async {
    if (getSavedAddressesUseCase == null) return;
    emit(state.copyWith(isLoadingAddresses: true));
    final result = await getSavedAddressesUseCase!();
    switch (result) {
      case Success(:final data):
        final addresses = data;
        final picked = addresses
            .where((a) => a.id == event.selectId)
            .firstOrNull;
        final currentSelected = state.selectedAddress;
        final selected =
            picked ??
            currentSelected ??
            (addresses.isNotEmpty ? addresses.first : null);
        emit(
          state.copyWith(
            isLoadingAddresses: false,
            savedAddresses: addresses,
            selectedAddress: selected,
            locationAddress: picked != null
                ? picked.formattedAddress
                : selected?.formattedAddress ?? state.locationAddress,
            addressId: selected?.id ?? state.addressId,
            locationCity: selected?.city ?? state.locationCity,
            locationDistrict: selected?.district ?? state.locationDistrict,
          ),
        );
      case Failed():
        emit(state.copyWith(isLoadingAddresses: false));
    }
  }

  void _onAddressSelected(
    ClientPostProjectAddressSelected event,
    Emitter<ClientPostProjectState> emit,
  ) {
    final addresses = state.savedAddresses.any((a) => a.id == event.address.id)
        ? state.savedAddresses
        : [event.address, ...state.savedAddresses];
    emit(
      state.copyWith(
        savedAddresses: addresses,
        selectedAddress: event.address,
        locationAddress: event.address.formattedAddress,
        addressId: event.address.id,
        locationCity: event.address.city,
        locationDistrict: event.address.district,
      ),
    );
  }

  Future<void> _onAddressCreated(
    ClientPostProjectAddressCreated event,
    Emitter<ClientPostProjectState> emit,
  ) async {
    if (createAddressUseCase == null) return;
    emit(state.copyWith(isLoadingAddresses: true));
    final result = await createAddressUseCase!(
      ClientCreateAddressParams(
        name: event.name,
        city: event.city,
        district: event.district,
        street: event.street,
        buildingNumber: event.buildingNumber,
        postalCode: event.postalCode,
      ),
    );
    switch (result) {
      case Success(:final data):
        final newAddress = data;
        final updatedList = [newAddress, ...state.savedAddresses];
        emit(
          state.copyWith(
            isLoadingAddresses: false,
            savedAddresses: updatedList,
            selectedAddress: newAddress,
            locationAddress: newAddress.formattedAddress,
            addressId: newAddress.id,
            locationCity: newAddress.city,
            locationDistrict: newAddress.district,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(isLoadingAddresses: false, failure: failure));
    }
  }

  void _onLocationChanged(
    ClientPostProjectLocationChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        locationAddress: event.location,
        addressId: event.addressId ?? state.addressId,
        locationCity: event.city ?? state.locationCity,
        locationDistrict: event.district ?? state.locationDistrict,
      ),
    );
  }

  void _onPhotoAdded(
    ClientPostProjectPhotoAdded event,
    Emitter<ClientPostProjectState> emit,
  ) {
    final updated = [...state.photos, event.photo];
    emit(state.copyWith(photos: updated));
  }

  void _onPhotoRemoved(
    ClientPostProjectPhotoRemoved event,
    Emitter<ClientPostProjectState> emit,
  ) {
    final updated = [...state.photos]..removeAt(event.index);
    emit(state.copyWith(photos: updated));
  }

  void _onDeedSelected(
    ClientPostProjectDeedSelected event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        deedFilePath: event.filePath,
        deedFileName: event.fileName,
        deedStatus: ClientDeedVerificationStatus.none,
        clearDeed: false,
      ),
    );
  }

  void _onDeedStatusChanged(
    ClientPostProjectDeedStatusChanged event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        deedStatus: event.status,
        deedRejectionReason: event.rejectionReason,
      ),
    );
  }

  void _onDeedRetry(
    ClientPostProjectDeedRetry event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(
      state.copyWith(
        clearDeed: true,
        deedStatus: ClientDeedVerificationStatus.none,
      ),
    );
  }

  void _onStepAdvanced(
    ClientPostProjectStepAdvanced event,
    Emitter<ClientPostProjectState> emit,
  ) {
    if (state.currentStep < state.totalSteps) {
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          status: ClientPostProjectStatus.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void _onStepRetreated(
    ClientPostProjectStepRetreated event,
    Emitter<ClientPostProjectState> emit,
  ) {
    if (state.currentStep > 1) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          status: ClientPostProjectStatus.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void _onReset(
    ClientPostProjectReset event,
    Emitter<ClientPostProjectState> emit,
  ) {
    emit(const ClientPostProjectState());
  }

  Future<void> _onSubmitted(
    ClientPostProjectSubmitted event,
    Emitter<ClientPostProjectState> emit,
  ) async {
    emit(state.copyWith(status: ClientPostProjectStatus.submitting));

    if (createProjectUseCase == null) {
      emit(state.copyWith(status: ClientPostProjectStatus.success));
      return;
    }

    final addressText = state.locationAddress ?? '';
    final parts = addressText.split('·').map((p) => p.trim()).toList();
    final city =
        state.locationCity ??
        state.selectedAddress?.city ??
        (parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : '');
    final district =
        state.locationDistrict ??
        state.selectedAddress?.district ??
        (parts.length > 1 ? parts[1] : null);

    final typeName = state.projectType?.name ?? 'project';
    final title = state.scopeOfWork.isNotEmpty
        ? state.scopeOfWork.split('\n').first.trim()
        : typeName;

    final result = await createProjectUseCase!(
      ClientNewProject(
        title: title,
        city: city,
        district: district,
        addressId: state.selectedAddress?.id ?? state.addressId,
        description: state.scopeOfWork.isNotEmpty ? state.scopeOfWork : null,
        budget: state.settledBudget,
        publish: !state.requiresDeed,
        photos: state.photos,
        deedFilePath: state.deedFilePath,
      ),
    );

    switch (result) {
      case Success():
        emit(state.copyWith(status: ClientPostProjectStatus.success));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientPostProjectStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
