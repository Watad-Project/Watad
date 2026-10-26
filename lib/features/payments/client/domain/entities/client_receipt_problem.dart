/// Why a receipt can't be sent (GRA-52), with the translation key that
/// says so.
enum ClientReceiptProblem {
  /// Not a PDF, JPEG or PNG.
  wrongType('payments.client.receipt_type'),

  /// The file has nothing in it.
  empty('payments.client.receipt_empty'),

  /// Over 10 MB, the bucket's limit.
  tooLarge('validation.file_too_large');

  const ClientReceiptProblem(this.messageKey);

  final String messageKey;
}
