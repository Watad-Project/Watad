import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';

/// The photo at the top of the edit form (GRA-60): the one just picked,
/// the saved one, or the default avatar, with «تغيير الصورة» under it.
class ProfilePhotoField extends StatelessWidget {
  const ProfilePhotoField({
    required this.change,
    this.url,
    this.semanticLabel,
    this.onChange,
    super.key,
  });

  /// What «حفظ» will do with the photo.
  final ProfilePhotoChange change;

  /// The saved photo's URL.
  final String? url;
  final String? semanticLabel;

  /// Opens the choice of camera, gallery or removing; null while the form
  /// can't change.
  final VoidCallback? onChange;

  /// The photo's diameter.
  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    return Column(
      children: [
        AppAvatar(
          url: change is ProfilePhotoRemoved ? null : url,
          image: change is ProfilePhotoReplaced
              ? MemoryImage(change.photo.bytes)
              : null,
          size: _size,
          semanticLabel: semanticLabel,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('profile_edit_photo'),
          label: context.tr('profile.edit.photo_change'),
          icon: Icons.photo_camera_outlined,
          variant: AppButtonVariant.link,
          onPressed: onChange,
        ),
      ],
    );
  }
}
