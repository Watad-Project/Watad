import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_type.dart';
import 'package:watad/features/profile/shared/domain/usecases/prepare_profile_photo_use_case.dart';

void main() {
  /// A JPEG of [size] bytes: its signature, then zeros.
  Uint8List jpeg(int size) => Uint8List(size)
    ..[0] = 0xFF
    ..[1] = 0xD8
    ..[2] = 0xFF;

  test('a JPEG within 2 MB is ready to upload', () async {
    final result = await const PrepareProfilePhotoUseCase()(
      jpeg(PrepareProfilePhotoUseCase.maxBytes),
    );

    switch (result) {
      case Success(:final data):
        expect(data.type, ProfilePhotoType.jpeg);
        expect(data.bytes.length, PrepareProfilePhotoUseCase.maxBytes);
      case Failed():
        fail('Expected the photo');
    }
  });

  test('a photo over 2 MB is refused', () async {
    final result = await const PrepareProfilePhotoUseCase()(
      jpeg(PrepareProfilePhotoUseCase.maxBytes + 1),
    );

    switch (result) {
      case Failed(:final failure):
        expect(failure, isA<ValidationFailure>());
        expect(failure.messageKey, 'profile.edit.photo_too_large');
      case Success():
        fail('Expected a refusal');
    }
  });

  test('a file that is no JPEG, PNG or WebP is refused', () async {
    // "GIF89a".
    final gif = Uint8List.fromList(const [
      0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0, //
    ]);

    final result = await const PrepareProfilePhotoUseCase()(gif);

    switch (result) {
      case Failed(:final failure):
        expect(failure.messageKey, 'profile.edit.photo_type_invalid');
      case Success():
        fail('Expected a refusal');
    }
  });
}
