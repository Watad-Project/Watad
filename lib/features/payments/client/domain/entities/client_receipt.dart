import 'dart:typed_data';

import 'package:watad/features/payments/client/domain/entities/client_receipt_problem.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt_type.dart';

/// The transfer receipt the client picked (GRA-52): the file's bytes, and
/// its name on the phone, which is only shown (the upload gets a new name).
class ClientReceipt {
  const ClientReceipt({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  /// The most the `bank-transfer-receipts` bucket takes: 10 MB.
  static const int maxBytes = 10 * 1024 * 1024;

  /// PDF, JPEG or PNG, from the name's extension; null for anything else
  /// (e.g. an iPhone's HEIC photo).
  ClientReceiptType? get type => switch (name.split('.').last.toLowerCase()) {
    'pdf' => ClientReceiptType.pdf,
    'jpg' || 'jpeg' => ClientReceiptType.jpeg,
    'png' => ClientReceiptType.png,
    _ => null,
  };

  /// Why it can't be sent, or null when it can.
  ClientReceiptProblem? get problem {
    if (type == null) return ClientReceiptProblem.wrongType;
    if (bytes.isEmpty) return ClientReceiptProblem.empty;
    if (bytes.length > maxBytes) return ClientReceiptProblem.tooLarge;
    return null;
  }
}
