import 'dart:typed_data';

/// The image types the `avatars` bucket takes (migration 01), told from
/// the file's first bytes, never from its name.
enum ProfilePhotoType {
  jpeg('jpg', 'image/jpeg'),
  png('png', 'image/png'),
  webp('webp', 'image/webp');

  const ProfilePhotoType(this.extension, this.contentType);

  /// The end of the file name in the bucket, e.g. `avatar_1700000000000.jpg`.
  final String extension;
  final String contentType;

  /// The type of [bytes], or null when it's none of the three (a HEIC or
  /// GIF photo, or not an image at all).
  static ProfilePhotoType? of(Uint8List bytes) {
    bool has(List<int> signature, [int offset = 0]) {
      if (bytes.length < offset + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    if (has(const [0xFF, 0xD8, 0xFF])) return jpeg;
    if (has(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return png;
    }
    // "RIFF", the size, then "WEBP".
    if (has(const [0x52, 0x49, 0x46, 0x46]) &&
        has(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return webp;
    }
    return null;
  }
}
