part of 'profile_edit_bloc.dart';

enum ProfileEditStatus { initial, loading, ready, failure, saved }

/// How a [ProfileEditMessage] shows: with a green check, as a plain note,
/// or with a red mark.
enum ProfileEditMessageKind { success, info, error }

/// A message to show once, as a translation key.
final class ProfileEditMessage {
  const ProfileEditMessage(this.key, this.kind);

  ProfileEditMessage.error(Failure failure)
    : this(failure.messageKey, ProfileEditMessageKind.error);

  final String key;
  final ProfileEditMessageKind kind;
}

final class ProfileEditState {
  const ProfileEditState({
    this.status = ProfileEditStatus.initial,
    this.data,
    this.failure,
    this.check,
    this.photo = const ProfilePhotoKept(),
    this.specializedField,
    this.city,
    this.isSaving = false,
    this.crNumberTaken = false,
    this.outcome,
    this.message,
  });

  final ProfileEditStatus status;

  /// The profile as the server has it, and the identity.
  final ProfileEditData? data;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The text fields as typed, cleaned and checked.
  final ProfileFormCheck? check;
  final ProfilePhotoChange photo;

  /// The picked specialty's label; null keeps the saved one.
  final String? specializedField;

  /// The picked city; null keeps the saved one.
  final String? city;
  final bool isSaving;

  /// The server said the CR number sent belongs to another business.
  final bool crNumberTaken;

  /// The last save, when it stored only part of the changes.
  final ProfileSaveOutcome? outcome;
  final ProfileEditMessage? message;

  MyProfile? get profile => data?.profile;

  /// The form can change: it's loaded, not saving, and the account isn't
  /// suspended (the server would refuse every write).
  bool get isEditable =>
      status == ProfileEditStatus.ready &&
      !isSaving &&
      !(profile?.isSuspended ?? true);

  /// What «حفظ» would send.
  ProfileChanges get changes {
    final profile = this.profile;
    final check = this.check;
    if (profile == null || check == null) return const ProfileChanges();
    return ProfileChanges.between(
      profile: profile,
      check: check,
      photo: photo,
      specializedField: specializedField,
      city: city,
    );
  }

  bool get hasChanges => !changes.isEmpty;

  /// Something changed, and every field is right.
  bool get canSave => isEditable && (check?.isValid ?? false) && hasChanges;

  /// Saving sends the business back to `unverified`: «حفظ» asks first.
  bool get unverifiesBusiness => changes.unverifiesBusiness;

  /// A verified business's CR number can't change (migration 86).
  bool get isCrNumberLocked =>
      profile?.business?.verificationStatus == VerificationStatus.verified;

  /// Each field's problem, as a translation key, once the field has
  /// something in it. An empty field shows none: its label already says
  /// it's required.
  String? get fullNameError => _shown(check?.fullName, check?.fullNameError);

  String? get companyNameError =>
      _shown(check?.companyName, check?.companyNameError);

  String? get crNumberError => crNumberTaken
      ? 'profile.edit.cr_number_taken'
      : _shown(check?.crNumber, check?.crNumberError);

  static String? _shown(String? value, String? error) =>
      value == null || value.isEmpty ? null : error;

  ProfileEditState copyWith({
    ProfileEditStatus? status,
    ProfileEditData? Function()? data,
    Failure? Function()? failure,
    ProfileFormCheck? Function()? check,
    ProfilePhotoChange? photo,
    String? Function()? specializedField,
    String? Function()? city,
    bool? isSaving,
    bool? crNumberTaken,
    ProfileSaveOutcome? Function()? outcome,
    ProfileEditMessage? Function()? message,
  }) {
    return ProfileEditState(
      status: status ?? this.status,
      data: data == null ? this.data : data(),
      failure: failure == null ? this.failure : failure(),
      check: check == null ? this.check : check(),
      photo: photo ?? this.photo,
      specializedField: specializedField == null
          ? this.specializedField
          : specializedField(),
      city: city == null ? this.city : city(),
      isSaving: isSaving ?? this.isSaving,
      crNumberTaken: crNumberTaken ?? this.crNumberTaken,
      outcome: outcome == null ? this.outcome : outcome(),
      message: message == null ? this.message : message(),
    );
  }
}
