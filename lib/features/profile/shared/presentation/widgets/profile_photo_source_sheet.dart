import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The sheet «تغيير الصورة» opens (GRA-60): take a photo, pick one from the
/// gallery, or remove the photo when there is one. A choice closes the
/// sheet, then acts.
class ProfilePhotoSourceSheet extends StatelessWidget {
  const ProfilePhotoSourceSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
    super.key,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  /// Null when there's no photo to remove.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final onRemove = this.onRemove;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('profile.edit.photo_title'),
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('profile_photo_camera'),
              label: context.tr('profile.edit.photo_camera'),
              icon: Icons.photo_camera_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                onCamera();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const Key('profile_photo_gallery'),
              label: context.tr('profile.edit.photo_gallery'),
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).pop();
                onGallery();
              },
            ),
            if (onRemove != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('profile_photo_remove'),
                label: context.tr('profile.edit.photo_remove'),
                icon: Icons.delete_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).pop();
                  onRemove();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
