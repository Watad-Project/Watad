import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt_type.dart';
import 'package:watad/features/payments/client/domain/usecases/client_check_receipt_use_case.dart';

void main() {
  const check = ClientCheckReceiptUseCase();
  final bytes = Uint8List.fromList([1, 2, 3]);

  String failureKey(Result<ClientReceipt> result) =>
      (result as Failed<ClientReceipt>).failure.messageKey;

  test('takes a PDF, a JPEG or a PNG', () async {
    for (final (name, type) in [
      ('receipt.pdf', ClientReceiptType.pdf),
      ('photo.jpg', ClientReceiptType.jpeg),
      ('IMG_2026.JPEG', ClientReceiptType.jpeg),
      ('screenshot.png', ClientReceiptType.png),
    ]) {
      final result = await check(ClientReceipt(bytes: bytes, name: name));

      expect((result as Success<ClientReceipt>).data.type, type, reason: name);
    }
  });

  test('takes every extension the file picker offers', () async {
    for (final extension in ClientReceipt.extensions) {
      final result = await check(
        ClientReceipt(bytes: bytes, name: 'receipt.$extension'),
      );

      expect(result, isA<Success<ClientReceipt>>(), reason: extension);
    }
  });

  test('refuses any other kind of file, e.g. an iPhone\'s HEIC', () async {
    for (final name in ['IMG_0001.HEIC', 'animation.gif', 'receipt']) {
      final result = await check(ClientReceipt(bytes: bytes, name: name));

      expect(failureKey(result), 'payments.client.receipt_type', reason: name);
    }
  });

  test('refuses an empty file', () async {
    final result = await check(
      ClientReceipt(bytes: Uint8List(0), name: 'receipt.pdf'),
    );

    expect(failureKey(result), 'payments.client.receipt_empty');
  });

  test('takes up to 10 MB, no more', () async {
    expect(
      await check(
        ClientReceipt(
          bytes: Uint8List(ClientReceipt.maxBytes),
          name: 'receipt.pdf',
        ),
      ),
      isA<Success<ClientReceipt>>(),
    );

    final result = await check(
      ClientReceipt(
        bytes: Uint8List(ClientReceipt.maxBytes + 1),
        name: 'receipt.pdf',
      ),
    );
    expect(failureKey(result), 'validation.file_too_large');
  });
}
