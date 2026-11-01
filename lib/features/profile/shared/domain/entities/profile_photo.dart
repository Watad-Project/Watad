import 'dart:typed_data';

import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';

/// A photo picked for the profile (GRA-60), checked and ready to upload.
class ProfilePhoto {
  const ProfilePhoto({required this.bytes, required this.type});

  final Uint8List bytes;
  final ProfilePhotoType type;
}
