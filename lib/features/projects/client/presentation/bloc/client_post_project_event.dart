part of 'client_post_project_bloc.dart';

sealed class ClientPostProjectEvent {
  const ClientPostProjectEvent();
}

/// The user selected or changed a project type.
final class ClientPostProjectTypeSelected extends ClientPostProjectEvent {
  const ClientPostProjectTypeSelected(this.type);

  final ClientProjectType type;
}

/// The user typed or changed the scope of work (step 2).
final class ClientPostProjectScopeChanged extends ClientPostProjectEvent {
  const ClientPostProjectScopeChanged(this.scope);

  final String scope;
}

/// The user changed the minimum budget (step 2).
final class ClientPostProjectMinBudgetChanged extends ClientPostProjectEvent {
  const ClientPostProjectMinBudgetChanged(this.minBudget);

  final Money? minBudget;
}

/// The user changed the maximum budget (step 2).
final class ClientPostProjectMaxBudgetChanged extends ClientPostProjectEvent {
  const ClientPostProjectMaxBudgetChanged(this.maxBudget);

  final Money? maxBudget;
}

/// Load client's saved addresses from Supabase `v_my_addresses`.
final class ClientPostProjectAddressesRequested extends ClientPostProjectEvent {
  const ClientPostProjectAddressesRequested({this.selectId});

  /// The address to select once loaded, e.g. one just saved on the map.
  final String? selectId;
}

/// The user selected an address from their saved Supabase addresses.
final class ClientPostProjectAddressSelected extends ClientPostProjectEvent {
  const ClientPostProjectAddressSelected(this.address);

  final ClientSavedAddress address;
}

/// The user created a new address to save to Supabase `addresses`.
final class ClientPostProjectAddressCreated extends ClientPostProjectEvent {
  const ClientPostProjectAddressCreated({
    required this.name,
    required this.city,
    required this.district,
    required this.street,
    required this.buildingNumber,
    required this.postalCode,
  });

  final String name;
  final String city;
  final String district;
  final String street;
  final String buildingNumber;
  final String postalCode;
}

/// The user selected or changed the location address (step 2).
final class ClientPostProjectLocationChanged extends ClientPostProjectEvent {
  const ClientPostProjectLocationChanged(
    this.location, {
    this.addressId,
    this.city,
    this.district,
  });

  final String location;
  final String? addressId;
  final String? city;
  final String? district;
}

/// The user added a photo (step 2).
final class ClientPostProjectPhotoAdded extends ClientPostProjectEvent {
  const ClientPostProjectPhotoAdded(this.photo);

  final String photo;
}

/// The user removed a photo by index (step 2).
final class ClientPostProjectPhotoRemoved extends ClientPostProjectEvent {
  const ClientPostProjectPhotoRemoved(this.index);

  final int index;
}

/// The user selected or uploaded a property ownership deed document (step 3).
final class ClientPostProjectDeedSelected extends ClientPostProjectEvent {
  const ClientPostProjectDeedSelected({required this.filePath, this.fileName});

  final String filePath;
  final String? fileName;
}

/// Status changed for the deed verification process (step 3).
final class ClientPostProjectDeedStatusChanged extends ClientPostProjectEvent {
  const ClientPostProjectDeedStatusChanged(this.status, {this.rejectionReason});

  final ClientDeedVerificationStatus status;
  final String? rejectionReason;
}

/// The user retries uploading the deed document (step 3).
final class ClientPostProjectDeedRetry extends ClientPostProjectEvent {
  const ClientPostProjectDeedRetry();
}

/// The user requests to advance to the next step.
final class ClientPostProjectStepAdvanced extends ClientPostProjectEvent {
  const ClientPostProjectStepAdvanced();
}

/// The user requests to go back to the previous step.
final class ClientPostProjectStepRetreated extends ClientPostProjectEvent {
  const ClientPostProjectStepRetreated();
}

/// Reset the entire post-project flow.
final class ClientPostProjectReset extends ClientPostProjectEvent {
  const ClientPostProjectReset();
}

/// Final submit of the project to backend.
final class ClientPostProjectSubmitted extends ClientPostProjectEvent {
  const ClientPostProjectSubmitted();
}
