import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';

void main() {
  Uint8List bytes(List<int> start) =>
      Uint8List.fromList([...start, ...List.filled(16, 0)]);

  test('JPEG, PNG and WebP are told from their first bytes', () {
    expect(
      ProfilePhotoType.of(bytes(const [0xFF, 0xD8, 0xFF, 0xE0])),
      ProfilePhotoType.jpeg,
    );
    expect(
      ProfilePhotoType.of(
        bytes(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      ),
      ProfilePhotoType.png,
    );
    // "RIFF", 4 bytes of size, "WEBP".
    expect(
      ProfilePhotoType.of(
        bytes(const [
          0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, //
          0x57, 0x45, 0x42, 0x50,
        ]),
      ),
      ProfilePhotoType.webp,
    );
  });

  test('anything else is no type', () {
    // "GIF89a", a HEIC's "ftypheic" box, a RIFF that isn't WebP, too short.
    expect(
      ProfilePhotoType.of(bytes(const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61])),
      isNull,
    );
    expect(
      ProfilePhotoType.of(
        bytes(const [
          0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, //
          0x68, 0x65, 0x69, 0x63,
        ]),
      ),
      isNull,
    );
    expect(
      ProfilePhotoType.of(
        bytes(const [
          0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, //
          0x57, 0x41, 0x56, 0x45,
        ]),
      ),
      isNull,
    );
    expect(ProfilePhotoType.of(Uint8List.fromList(const [0xFF])), isNull);
  });

  test('each type has the extension and content type the bucket takes', () {
    expect(ProfilePhotoType.jpeg.extension, 'jpg');
    expect(ProfilePhotoType.jpeg.contentType, 'image/jpeg');
    expect(ProfilePhotoType.png.contentType, 'image/png');
    expect(ProfilePhotoType.webp.contentType, 'image/webp');
  });
}
