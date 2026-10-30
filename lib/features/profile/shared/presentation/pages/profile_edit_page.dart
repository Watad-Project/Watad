import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_edit_data.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_draft.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_city_search_bloc.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_edit_bloc.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_business_fields.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_city_sheet.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_identity_section.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_photo_field.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_photo_source_sheet.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_save_result_card.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_suspension_banner.dart';

/// «تعديل الملف الشخصي» (GRA-60), for every role: the name and photo, a
/// contractor's business (shown when the profile has one), and the
/// identity given at sign-up, read-only.
///
/// «حفظ» stays off until something changed and every field is right. A
/// save that un-verifies the business asks first, and so does leaving with
/// changes. After a full save the page closes, and the account tab shows
/// what the server stored.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  /// The longest side of a picked photo. With [_photoQuality] it keeps the
  /// file under the bucket's 2 MB, and turns an iPhone's HEIC into JPEG.
  static const double _photoMaxSide = 1024;
  static const int _photoQuality = 80;

  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _crNumber = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _companyName.dispose();
    _crNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // The form opened on the saved values.
        BlocListener<ProfileEditBloc, ProfileEditState>(
          listenWhen: (previous, current) =>
              current.status == ProfileEditStatus.ready &&
              previous.status == ProfileEditStatus.loading,
          listener: (context, state) => _fill(state.profile),
        ),
        BlocListener<ProfileEditBloc, ProfileEditState>(
          listenWhen: (previous, current) =>
              current.message != null && current.message != previous.message,
          listener: _showMessage,
        ),
        // Everything was saved: back to the account tab.
        BlocListener<ProfileEditBloc, ProfileEditState>(
          listenWhen: (previous, current) =>
              current.status == ProfileEditStatus.saved &&
              previous.status != ProfileEditStatus.saved,
          listener: (context, state) {
            if (context.canPop()) context.pop(true);
          },
        ),
      ],
      child: BlocBuilder<ProfileEditBloc, ProfileEditState>(
        builder: (context, state) {
          final bloc = context.read<ProfileEditBloc>();
          final data = state.data;
          return PopScope(
            canPop:
                !state.hasChanges || state.status == ProfileEditStatus.saved,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _leave();
            },
            child: Scaffold(
              appBar: AppTopBar(
                title: context.tr('profile.edit.title'),
                onBack: _leave,
              ),
              body: AnimatedSwitcher(
                duration: AppMotion.enter,
                reverseDuration: AppMotion.exit,
                switchInCurve: AppMotion.enterCurve,
                switchOutCurve: AppMotion.exitCurve,
                child: switch (state) {
                  ProfileEditState(
                    status: ProfileEditStatus.failure,
                    :final failure?,
                  ) =>
                    AppErrorView(
                      key: const ValueKey('error'),
                      message: context.tr(failure.messageKey),
                      onRetry: () => bloc.add(const ProfileEditFetched()),
                    ),
                  ProfileEditState(:final data?) => _ProfileEditForm(
                    key: const ValueKey('form'),
                    state: state,
                    data: data,
                    fullNameController: _fullName,
                    companyNameController: _companyName,
                    crNumberController: _crNumber,
                    onTyped: () => _onTyped(data.profile),
                    onChangePhoto: () => _changePhoto(state),
                    onPickCity: _pickCity,
                  ),
                  _ => const AppLoadingIndicator(key: ValueKey('loading')),
                },
              ),
              bottomNavigationBar: data == null
                  ? null
                  : AppActionBar(
                      primary: AppButton(
                        key: const Key('profile_edit_save'),
                        label: context.tr('profile.edit.save'),
                        isLoading: state.isSaving,
                        onPressed: state.canSave ? () => _save(state) : null,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _fill(MyProfile? profile) {
    _fullName.text = profile?.fullName ?? '';
    _companyName.text = profile?.business?.companyName ?? '';
    _crNumber.text = profile?.business?.crNumber ?? '';
  }

  void _onTyped(MyProfile profile) {
    final hasBusiness = profile.business != null;
    context.read<ProfileEditBloc>().add(
      ProfileEditFormChanged(
        ProfileFormDraft(
          fullName: _fullName.text,
          companyName: hasBusiness ? _companyName.text : null,
          crNumber: hasBusiness ? _crNumber.text : null,
        ),
      ),
    );
  }

  /// «حفظ». When the save sends the business back to unverified, the
  /// contractor confirms first.
  Future<void> _save(ProfileEditState state) async {
    final bloc = context.read<ProfileEditBloc>();
    if (state.unverifiesBusiness) {
      final verified =
          state.profile?.business?.verificationStatus ==
          VerificationStatus.verified;
      final confirmed = await AppConfirmDialog.show(
        context,
        title: context.tr('profile.edit.unverify_title'),
        message: context.tr(
          verified
              ? 'profile.edit.unverify_message_verified'
              : 'profile.edit.unverify_message_pending',
        ),
        confirmLabel: context.tr('profile.edit.unverify_confirm'),
      );
      if (confirmed == null) return;
    }
    bloc.add(const ProfileEditSubmitted());
  }

  /// The back arrow or the back gesture: with unsaved changes, ask first.
  Future<void> _leave() async {
    final state = context.read<ProfileEditBloc>().state;
    if (state.isSaving) return;
    if (state.hasChanges && state.status != ProfileEditStatus.saved) {
      final leave = await AppConfirmDialog.show(
        context,
        title: context.tr('profile.edit.leave_title'),
        message: context.tr('profile.edit.leave_message'),
        confirmLabel: context.tr('profile.edit.leave_confirm'),
      );
      if (leave == null) return;
    }
    if (mounted && context.canPop()) context.pop();
  }

  Future<void> _changePhoto(ProfileEditState state) async {
    final bloc = context.read<ProfileEditBloc>();
    final hasPhoto = switch (state.photo) {
      ProfilePhotoReplaced() => true,
      ProfilePhotoRemoved() => false,
      ProfilePhotoKept() => state.profile?.avatarPath != null,
    };
    await AppPopup.sheet<void>(
      context,
      builder: (_) => ProfilePhotoSourceSheet(
        onCamera: () => _pickPhoto(bloc, ImageSource.camera),
        onGallery: () => _pickPhoto(bloc, ImageSource.gallery),
        onRemove: hasPhoto ? () => _removePhoto(bloc) : null,
      ),
    );
  }

  /// image_picker asks for the camera itself; the bloc checks the photo's
  /// type and size.
  Future<void> _pickPhoto(ProfileEditBloc bloc, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: _photoMaxSide,
        maxHeight: _photoMaxSide,
        imageQuality: _photoQuality,
        requestFullMetadata: false,
      );
      if (file == null) return;
      bloc.add(ProfileEditPhotoPicked(await file.readAsBytes()));
    } on PlatformException catch (error) {
      if (!mounted) return;
      context.showErrorSnackBar(
        context.tr(
          error.code == 'camera_access_denied'
              ? 'profile.edit.camera_denied'
              : 'profile.edit.photo_pick_failed',
        ),
      );
    }
  }

  Future<void> _removePhoto(ProfileEditBloc bloc) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('profile.edit.photo_remove_title'),
      message: context.tr('profile.edit.photo_remove_message'),
      confirmLabel: context.tr('profile.edit.photo_remove'),
    );
    if (confirmed != null) bloc.add(const ProfileEditPhotoRemoved());
  }

  /// The city search, in a sheet that closes with the city it found.
  Future<void> _pickCity() async {
    final bloc = context.read<ProfileEditBloc>();
    final search = context.read<ProfileCitySearchBloc>()
      ..add(const ProfileCitySearchOpened());
    final city = await AppPopup.sheet<String>(
      context,
      builder: (_) =>
          BlocProvider.value(value: search, child: const ProfileCitySheet()),
    );
    if (city != null) bloc.add(ProfileEditCityPicked(city));
  }

  void _showMessage(BuildContext context, ProfileEditState state) {
    final message = state.message;
    if (message == null) return;
    final text = context.tr(message.key);
    switch (message.kind) {
      case ProfileEditMessageKind.success:
        context.showSuccessSnackBar(text);
      case ProfileEditMessageKind.info:
        context.showSnackBar(text);
      case ProfileEditMessageKind.error:
        context.showErrorSnackBar(text);
    }
  }
}

/// The form: what a save stored when it was only part, the suspension
/// banner, the photo, the name, the business, and the identity.
class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.state,
    required this.data,
    required this.fullNameController,
    required this.companyNameController,
    required this.crNumberController,
    required this.onTyped,
    required this.onChangePhoto,
    required this.onPickCity,
    super.key,
  });

  final ProfileEditState state;
  final ProfileEditData data;
  final TextEditingController fullNameController;
  final TextEditingController companyNameController;
  final TextEditingController crNumberController;
  final VoidCallback onTyped;
  final VoidCallback onChangePhoto;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    String? errorOf(String? key) => key == null ? null : context.tr(key);
    final bloc = context.read<ProfileEditBloc>();
    final profile = data.profile;
    final business = profile.business;
    final identity = data.identity;
    final outcome = state.outcome;
    final editable = state.isEditable;
    final name = profile.fullName.trim();
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        if (profile.isSuspended) ...[
          ProfileSuspensionBanner(reason: profile.suspensionReason),
          const SizedBox(height: AppSpacing.md),
        ],
        if (outcome != null) ...[
          ProfileSaveResultCard(
            outcome: outcome,
            businessReasonKey: state.crNumberTaken
                ? 'profile.edit.cr_number_taken'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ProfilePhotoField(
          change: state.photo,
          url: profile.avatarUrl,
          semanticLabel: name.isEmpty ? null : name,
          onChange: editable ? onChangePhoto : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          key: const Key('profile_edit_name'),
          label: context.tr('profile.edit.name'),
          isRequired: true,
          controller: fullNameController,
          hint: context.tr('profile.edit.name_hint'),
          errorText: errorOf(state.fullNameError),
          textInputAction: TextInputAction.next,
          enabled: editable,
          onChanged: (_) => onTyped(),
        ),
        if (business != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ProfileBusinessFields(
            business: business,
            companyNameController: companyNameController,
            crNumberController: crNumberController,
            onChanged: onTyped,
            onSpecialtyPicked: (label) =>
                bloc.add(ProfileEditSpecialtyPicked(label)),
            pickedSpecialty: state.specializedField,
            city: state.city ?? business.city,
            onCityTap: editable ? onPickCity : null,
            companyNameError: state.companyNameError,
            crNumberError: state.crNumberError,
            enabled: editable,
          ),
        ],
        if (identity != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ProfileIdentitySection(identity: identity),
        ],
      ],
    );
  }
}
