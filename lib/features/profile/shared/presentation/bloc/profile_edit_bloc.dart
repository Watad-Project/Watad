import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_edit_data.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_draft.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_outcome.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_part.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_save_request.dart';
import 'package:watad/features/profile/shared/domain/usecases/check_profile_form_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/get_profile_edit_data_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/prepare_profile_photo_use_case.dart';
import 'package:watad/features/profile/shared/domain/usecases/save_profile_use_case.dart';

part 'profile_edit_event.dart';
part 'profile_edit_state.dart';

/// «تعديل الملف الشخصي» (GRA-60): the user's name and photo, and a
/// contractor's business. Every change is checked; «حفظ» sends only what
/// changed and then shows what the server stored.
class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  ProfileEditBloc(
    this._getData,
    this._checkForm,
    this._preparePhoto,
    this._save,
  ) : super(const ProfileEditState()) {
    on<ProfileEditFetched>(_onFetched);
    on<ProfileEditFormChanged>(_onFormChanged);
    on<ProfileEditSpecialtyPicked>(_onSpecialtyPicked);
    on<ProfileEditCityPicked>(_onCityPicked);
    on<ProfileEditPhotoPicked>(_onPhotoPicked);
    on<ProfileEditPhotoRemoved>(_onPhotoRemoved);
    on<ProfileEditSubmitted>(_onSubmitted);
  }

  final GetProfileEditDataUseCase _getData;
  final CheckProfileFormUseCase _checkForm;
  final PrepareProfilePhotoUseCase _preparePhoto;
  final SaveProfileUseCase _save;

  Future<void> _onFetched(
    ProfileEditFetched event,
    Emitter<ProfileEditState> emit,
  ) async {
    emit(const ProfileEditState(status: ProfileEditStatus.loading));
    switch (await _getData(const NoParams())) {
      case Failed(:final failure):
        emit(
          ProfileEditState(status: ProfileEditStatus.failure, failure: failure),
        );
      case Success(:final data):
        // The form opens on the saved values: nothing to save yet.
        final profile = data.profile;
        final business = profile.business;
        final check = await _checkForm(
          ProfileFormDraft(
            fullName: profile.fullName,
            companyName: business?.companyName,
            crNumber: business?.crNumber,
          ),
        );
        emit(switch (check) {
          Success(data: final check) => ProfileEditState(
            status: ProfileEditStatus.ready,
            data: data,
            check: check,
          ),
          Failed(:final failure) => ProfileEditState(
            status: ProfileEditStatus.failure,
            failure: failure,
          ),
        });
    }
  }

  Future<void> _onFormChanged(
    ProfileEditFormChanged event,
    Emitter<ProfileEditState> emit,
  ) async {
    if (!state.isEditable) return;
    final result = await _checkForm(event.draft);
    if (!state.isEditable) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            check: () => data,
            // Taken was said of the number sent; a new one may be free.
            crNumberTaken:
                state.crNumberTaken && data.crNumber == state.check?.crNumber,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(message: () => ProfileEditMessage.error(failure)));
    }
  }

  void _onSpecialtyPicked(
    ProfileEditSpecialtyPicked event,
    Emitter<ProfileEditState> emit,
  ) {
    if (!state.isEditable) return;
    emit(state.copyWith(specializedField: () => event.label));
  }

  void _onCityPicked(
    ProfileEditCityPicked event,
    Emitter<ProfileEditState> emit,
  ) {
    if (!state.isEditable) return;
    emit(state.copyWith(city: () => event.city));
  }

  Future<void> _onPhotoPicked(
    ProfileEditPhotoPicked event,
    Emitter<ProfileEditState> emit,
  ) async {
    if (!state.isEditable) return;
    final result = await _preparePhoto(event.bytes);
    if (!state.isEditable) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(photo: ProfilePhotoReplaced(data)));
      case Failed(:final failure):
        emit(state.copyWith(message: () => ProfileEditMessage.error(failure)));
    }
  }

  void _onPhotoRemoved(
    ProfileEditPhotoRemoved event,
    Emitter<ProfileEditState> emit,
  ) {
    final profile = state.profile;
    if (profile == null || !state.isEditable) return;
    // A photo picked but not saved just goes; a saved one goes on «حفظ».
    emit(
      state.copyWith(
        photo: profile.avatarPath == null
            ? const ProfilePhotoKept()
            : const ProfilePhotoRemoved(),
      ),
    );
  }

  Future<void> _onSubmitted(
    ProfileEditSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    final data = state.data;
    final check = state.check;
    if (data == null || check == null || !state.canSave) return;
    final changes = state.changes;
    emit(state.copyWith(isSaving: true, message: () => null));
    final result = await _save(
      ProfileSaveRequest(
        profile: data.profile,
        check: check,
        photo: state.photo,
        specializedField: state.specializedField,
        city: state.city,
      ),
    );
    switch (result) {
      case Success(data: final outcome):
        emit(_afterSave(data, changes, outcome));
      case Failed(:final failure):
        emit(
          state.copyWith(
            isSaving: false,
            message: () => ProfileEditMessage.error(failure),
          ),
        );
    }
  }

  /// The state after «حفظ» got an answer. Everything saved: done, with what
  /// happened to the business. Something failed: the form stays as typed,
  /// measured against what the server has now, so only what wasn't saved
  /// still counts as a change.
  ProfileEditState _afterSave(
    ProfileEditData data,
    ProfileChanges changes,
    ProfileSaveOutcome outcome,
  ) {
    final saved = ProfileEditData(
      profile: outcome.profile ?? data.profile,
      identity: data.identity,
    );
    if (outcome.isComplete) {
      return ProfileEditState(
        status: ProfileEditStatus.saved,
        data: saved,
        check: state.check,
        message: ProfileEditMessage(
          _lostVerification(data.profile, outcome.profile)
              ? 'profile.edit.saved_unverified'
              : 'profile.edit.saved',
          ProfileEditMessageKind.success,
        ),
      );
    }
    final userFailure = _failureOf(outcome.user);
    final businessFailure = _failureOf(outcome.business);
    // `cr_number` is the only unique column the business part writes.
    final crNumberTaken =
        businessFailure is ConflictFailure && changes.business.crNumber != null;
    return state.copyWith(
      isSaving: false,
      data: () => saved,
      photo: outcome.user is ProfileSavePartSaved
          ? const ProfilePhotoKept()
          : state.photo,
      specializedField: () => outcome.business is ProfileSavePartSaved
          ? null
          : state.specializedField,
      city: () => outcome.business is ProfileSavePartSaved ? null : state.city,
      crNumberTaken: crNumberTaken,
      outcome: () => outcome.savedAnything ? outcome : null,
      message: () => ProfileEditMessage(
        crNumberTaken
            ? 'profile.edit.cr_number_taken'
            : (userFailure ?? businessFailure)?.messageKey ?? 'errors.unknown',
        ProfileEditMessageKind.error,
      ),
    );
  }

  static Failure? _failureOf(ProfileSavePart part) => switch (part) {
    ProfileSavePartFailed(:final failure) => failure,
    _ => null,
  };

  /// Whether the server now has the business `unverified` when it was
  /// `pending` or `verified` before the save.
  static bool _lostVerification(MyProfile before, MyProfile? after) {
    final was = before.business?.verificationStatus;
    return (was == VerificationStatus.pending ||
            was == VerificationStatus.verified) &&
        after?.business?.verificationStatus == VerificationStatus.unverified;
  }
}
