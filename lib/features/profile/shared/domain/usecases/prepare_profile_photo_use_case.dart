import 'dart:typed_data';

import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';

/// Checks a picked photo against the `avatars` bucket's rules before it's
/// uploaded (GRA-60, migration 01): a JPEG, PNG or WebP image, told from
/// its bytes, of at most 2 MB. The picker already makes it smaller and
/// turns an iPhone's HEIC into JPEG; this catches what's left.
class PrepareProfilePhotoUseCase implements UseCase<ProfilePhoto, Uint8List> {
  const PrepareProfilePhotoUseCase();

  /// The bucket's `file_size_limit`: 2 MB.
  static const int maxBytes = 2 * 1024 * 1024;

  @override
  Future<Result<ProfilePhoto>> call(Uint8List params) async {
    final type = ProfilePhotoType.of(params);
    if (type == null) {
      return const Failed(ValidationFailure('profile.edit.photo_type_invalid'));
    }
    if (params.length > maxBytes) {
      return const Failed(ValidationFailure('profile.edit.photo_too_large'));
    }
    return Success(ProfilePhoto(bytes: params, type: type));
  }
}
